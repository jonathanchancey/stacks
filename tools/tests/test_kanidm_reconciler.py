"""Safety and convergence tests for the client reconciler; no live credentials."""
import base64
from copy import deepcopy
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock
from urllib.error import HTTPError

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'flux/bastille/apps/auth-system/kanidm-client-reconciler/app/resources/reconcile.py'
spec = importlib.util.spec_from_file_location('reconcile', SOURCE)
r = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r)

CLIENT = {
    'name': 'example', 'displayName': 'Example', 'origin': 'https://example.test/',
    'redirectURLs': ['https://example.test/oauth2/callback'],
    'scopeMap': {'example_users': ['openid', 'profile', 'email']}, 'secretName': 'example-oidc-client',
}
NS = 'test'
CM = 'example-config'
PREFIX = '/api/v1/namespaces/test'
SECRET = PREFIX + '/secrets/example-oidc-client'
MARKER = 'managed by stacks kanidm-client-reconciler: test/example-config'


class FakeAPI:
    def __init__(self, objects=None):
        self.objects = deepcopy(objects or {})
        self.calls = []
        self.fail = None

    def call(self, method, path, body=None):
        self.calls.append((method, path, deepcopy(body)))
        if self.fail == (method, path):
            raise r.ReconcileError('simulated API failure')
        if method == 'GET':
            return deepcopy(self.objects.get(path))
        if method == 'POST' and path == '/v1/oauth2/_basic':
            attrs = deepcopy(body['attrs'])
            attrs.update({'uuid': ['client-uuid'], 'class': ['oauth2_resource_server_basic']})
            self.objects['/v1/oauth2/' + attrs['name'][0]] = {'attrs': attrs}
            self.objects['/v1/oauth2/' + attrs['name'][0] + '/_basic_secret'] = 'synthetic-test-credential'
        elif method == 'POST' and path == '/v1/group':
            attrs = deepcopy(body['attrs'])
            assert len(attrs['description']) == 1 and '\n' not in attrs['description'][0]
            attrs.update({'uuid': ['group-uuid'], 'class': ['group']})
            self.objects['/v1/group/' + attrs['name'][0]] = {'attrs': attrs}
        elif method == 'PATCH' and path.startswith('/v1/'):
            self.objects[path]['attrs'].update(deepcopy(body['attrs']))
        elif method == 'PATCH' and path == SECRET:
            obj = self.objects[path]
            obj.setdefault('data', {}).update(body['data'])
            obj['metadata']['annotations'].update(body['metadata']['annotations'])
        elif '/_scopemap/' in path:
            parent, group = path.split('/_scopemap/')
            attrs = self.objects[parent]['attrs']
            values = attrs.get('oauth2_rs_scope_map', [])
            values = [v for v in values if not v.startswith(group + ': ')]
            if method == 'POST':
                import json
                values.append(group + ': {' + ', '.join(json.dumps(v) for v in body) + '}')
            elif method != 'DELETE':
                raise AssertionError(method)
            attrs['oauth2_rs_scope_map'] = values
        else:
            raise AssertionError((method, path))

    def writes(self):
        return [c for c in self.calls if c[0] != 'GET']


def fixture():
    import json
    kube = FakeAPI({
        PREFIX + '/configmaps/' + CM: {'data': {'client.json': json.dumps(CLIENT)}},
        SECRET: {'metadata': {'resourceVersion': '1', 'annotations': {r.OWNER: NS + '/' + CM}}},
    })
    kanidm = FakeAPI({'/v1/group/example_users': {'attrs': {
        'class': ['group'], 'name': ['example_users'], 'spn': ['example_users@idm.test'], 'uuid': ['group-uuid'],
    }}})
    return kube, kanidm


class ReconcileTests(unittest.TestCase):
    def setUp(self):
        self.kube, self.kanidm = fixture()

    def run_client(self):
        r.reconcile_client(self.kube, self.kanidm, NS, CM)

    def change_client(self, **values):
        import json
        client = deepcopy(CLIENT)
        client.update(values)
        self.kube.objects[PREFIX + '/configmaps/' + CM]['data']['client.json'] = json.dumps(client)

    def test_create_then_no_writes_on_repeated_run(self):
        self.run_client()
        self.kube.calls.clear()
        self.kanidm.calls.clear()
        self.run_client()
        self.assertEqual(self.kube.writes(), [])
        self.assertEqual(self.kanidm.writes(), [])
        self.assertEqual(self.kube.objects[SECRET]['metadata']['annotations'][r.UUID_KEY], 'client-uuid')

    def test_missing_group_leaves_everything_untouched(self):
        self.kanidm.objects.clear()
        with self.assertRaisesRegex(r.ReconcileError, 'access group'):
            self.run_client()
        self.assertEqual(self.kanidm.writes() + self.kube.writes(), [])

    def test_unowned_secret_is_never_written(self):
        self.kube.objects[SECRET]['metadata']['annotations'].clear()
        with self.assertRaisesRegex(r.ReconcileError, 'not enrolled'):
            self.run_client()
        self.assertEqual(self.kanidm.calls, [])

    def test_unmarked_existing_client_needs_adoption(self):
        self.run_client()
        self.kanidm.objects['/v1/oauth2/example']['attrs']['description'] = ['manual client']
        self.kanidm.calls.clear()
        with self.assertRaisesRegex(r.ReconcileError, 'adoptExisting'):
            self.run_client()
        self.assertEqual(self.kanidm.writes(), [])
        self.change_client(adoptExisting=True)
        self.run_client()
        self.assertIn('manual client', self.kanidm.objects['/v1/oauth2/example']['attrs']['description'][0])

    def test_adoption_cannot_steal_another_declaration(self):
        self.run_client()
        self.kanidm.objects['/v1/oauth2/example']['attrs']['description'] = ['managed by stacks kanidm-client-reconciler: elsewhere/config']
        self.change_client(adoptExisting=True)
        with self.assertRaisesRegex(r.ReconcileError, 'another declaration'):
            self.run_client()

    def test_scope_revocation_precedes_grants(self):
        self.run_client()
        self.kanidm.objects['/v1/oauth2/example']['attrs']['oauth2_rs_scope_map'] = ['other-group: {"openid"}']
        self.kanidm.calls.clear()
        self.run_client()
        writes = self.kanidm.writes()
        self.assertEqual(writes[0][:2], ('DELETE', '/v1/oauth2/example/_scopemap/other-group'))
        self.assertEqual(writes[1][0], 'POST')

    def test_group_spn_is_recognized_without_rewriting(self):
        self.run_client()
        attrs = self.kanidm.objects['/v1/oauth2/example']['attrs']
        attrs['oauth2_rs_scope_map'] = [v.replace('group-uuid:', 'example_users@idm.test:') for v in attrs['oauth2_rs_scope_map']]
        self.kanidm.calls.clear()
        self.run_client()
        self.assertEqual(self.kanidm.writes(), [])

    def test_scope_failure_does_not_publish_credential(self):
        self.kanidm.fail = ('POST', '/v1/oauth2/example/_scopemap/group-uuid')
        with self.assertRaises(r.ReconcileError):
            self.run_client()
        self.assertEqual(self.kube.writes(), [])

    def test_retry_after_secret_write_failure_preserves_credential(self):
        self.kube.fail = ('PATCH', SECRET)
        with self.assertRaises(r.ReconcileError):
            self.run_client()
        self.kube.fail = None
        self.kanidm.calls.clear()
        self.run_client()
        self.assertEqual(self.kanidm.writes(), [])
        encoded = self.kube.objects[SECRET]['data']['client-secret']
        self.assertEqual(base64.b64decode(encoded), b'synthetic-test-credential')

    def test_replaced_or_missing_client_is_not_silently_recreated(self):
        self.run_client()
        self.kanidm.objects['/v1/oauth2/example']['attrs']['uuid'] = ['another-uuid']
        with self.assertRaisesRegex(r.ReconcileError, 'identity changed'):
            self.run_client()
        del self.kanidm.objects['/v1/oauth2/example']
        with self.assertRaisesRegex(r.ReconcileError, 'automatic replacement'):
            self.run_client()

    def test_changed_callback_removes_old_callback_without_secret_reset(self):
        self.run_client()
        self.change_client(redirectURLs=['https://example.test/new-callback'])
        self.kanidm.calls.clear()
        self.run_client()
        self.assertEqual(self.kanidm.writes(), [('PATCH', '/v1/oauth2/example', {'attrs': {'oauth2_rs_origin': ['https://example.test/new-callback']}})])

    def test_validation_rejects_unsafe_or_mistyped_declarations(self):
        cases = [{'name': '../flux'}, {'redirectURLs': ['https://other.test/callback']},
                 {'origin': 'http://example.test/'}, {'scopeMap': {}}, {'scopeMap': {'example_users': ['email']}},
                 {'adoptExisting': 'false'}, {'unknownField': True}, {'secretName': '../secret'}]
        for values in cases:
            with self.subTest(values=values):
                client = {**deepcopy(CLIENT), **values}
                with self.assertRaises(r.ReconcileError):
                    r.validate_client(client)

    def test_group_creation_and_updates_preserve_members(self):
        group = {'name': 'basic_users', 'description': 'Low risk services'}
        r.reconcile_group(self.kanidm, group)
        self.kanidm.objects['/v1/group/basic_users']['attrs']['member'] = ['private-member']
        self.kanidm.calls.clear()
        r.reconcile_group(self.kanidm, group)
        self.assertEqual(self.kanidm.writes(), [])
        group['description'] = 'Updated description'
        r.reconcile_group(self.kanidm, group)
        self.assertEqual(self.kanidm.objects['/v1/group/basic_users']['attrs']['member'], ['private-member'])

    def test_existing_group_needs_adoption_and_builtins_are_refused(self):
        group = {'name': 'example_users', 'description': 'Existing group'}
        with self.assertRaisesRegex(r.ReconcileError, 'adoptExisting'):
            r.reconcile_group(self.kanidm, group)
        with self.assertRaisesRegex(r.ReconcileError, 'ordinary application groups'):
            r.reconcile_group(self.kanidm, {'name': 'idm_admins', 'description': 'Forbidden', 'adoptExisting': True})

    def test_http_error_never_includes_credential_or_response_body(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'token'
            path.write_text('synthetic-secret')
            api = r.API('https://example.test', path)
            api.opener = Mock()
            api.opener.open.side_effect = HTTPError('https://example.test', 403, 'synthetic-secret', {}, io.BytesIO(b'synthetic-secret'))
            with self.assertRaises(r.ReconcileError) as error:
                api.call('POST', '/v1/oauth2/_basic', {'secret': 'synthetic-secret'})
            self.assertNotIn('synthetic-secret', str(error.exception))

    def test_authentication_redirects_are_not_followed(self):
        self.assertIsNone(r.NoRedirect().redirect_request(None, None, 302, '', {}, 'https://other.test'))
        with self.assertRaises(r.ReconcileError):
            r.API('http://example.test', '/missing-token')


if __name__ == '__main__':
    unittest.main()
