# fstab and passthrough


## okapi reap
UUID=819837de-7b37-43f1-bb94-333e6622cd07 /mnt/chia/cd07 ext4 defaults,nofail 0 1
UUID=b15ba535-eee2-4d12-9e98-da97f282ddd2 /mnt/chia/ddd2 ext4 defaults,nofail 0 1
UUID=6ae1b0d5-b0c3-4118-bebd-7f1f3ab78a48 /mnt/chia/8a48 ext4 defaults,nofail 0 1
UUID=eac05b2f-80c6-4a98-83cc-1a68547b3242 /mnt/chia/3242 ext4 defaults,nofail 0 1
UUID=6e51c717-beda-42f4-a1e8-58317320a1e8 /mnt/chia/a1e8 ext4 defaults,nofail 0 1
UUID=5640f44c-7c9a-47da-b854-b018fa95621a /mnt/chia/621a ext4 defaults,nofail 0 1


mkdir /mnt/chia/cd07
mkdir /mnt/chia/ddd2
mkdir /mnt/chia/8a48
mkdir /mnt/chia/3242
mkdir /mnt/chia/a1e8
mkdir /mnt/chia/621a

mp1: /mnt/chia/cd07,mp=/mnt/chia/cd07
mp2: /mnt/chia/ddd2,mp=/mnt/chia/ddd2
mp3: /mnt/chia/8a48,mp=/mnt/chia/8a48
mp4: /mnt/chia/3242,mp=/mnt/chia/3242
mp5: /mnt/chia/a1e8,mp=/mnt/chia/a1e8
mp6: /mnt/chia/621a,mp=/mnt/chia/621a

## vent suse vm

UUID=cf0c6835-e5b1-439b-9610-03e7c81d345d /mnt/chia/345d ext4 defaults,nofail 0 1
UUID=f75517c0-72d6-4b60-8b4d-22a1ad427f21 /mnt/chia/7f21 ext4 defaults,nofail 0 1
UUID=fca2c14c-ef33-4f44-a8d9-504dec23100a /mnt/chia/100a ext4 defaults,nofail 0 1
UUID=6a508991-4a10-49da-a195-9c787879aa99 /mnt/chia/aa99 ext4 defaults,nofail 0 1

sdb    cf0c6835-e5b1-439b-9610-03e7c81d345d
└─sdc1 f75517c0-72d6-4b60-8b4d-22a1ad427f21
sdd    fca2c14c-ef33-4f44-a8d9-504dec23100a
sde     7.3T
└─sde1  7.3T 6a508991-4a10-49da-a195-9c787879aa99

mkdir /mnt/chia
mkdir /mnt/chia/345d
mkdir /mnt/chia/7f21
mkdir /mnt/chia/100a
