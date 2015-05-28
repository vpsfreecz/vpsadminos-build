# We iz still in devel.
VERBOSE		= 1

STEP		=
ifneq ($(VERBOSE),)
V		= 
VRPM		= -v
VCURL		= -v
VTAR		= -v
else
V		= @
VRPM		= -q
VCURL		= -q
endif


ARCH		= x86_64
RELVER		= 6.6
RELRPMVER	= $(RELVER)-1
BASEURL		= http://mirror.vpsfree.cz/scientific/${RELVER}/$(ARCH)
BASEREPO	= $(BASEURL)/os
UPDATEREPO	= $(BASEURL)/updates/security
VPSADMINOSREPO	= http://repo.vpsfree.cz/
RELRPM		= $(BASEREPO)/Packages/sl-release-$(RELRPMVER).$(ARCH).rpm


DLTMP		= /storage/vpsadminos/dev/dltmp
INSTMP		= /storage/vpsadminos/dev/instmp
TARGET_FILENAME	= /storage/vpsadminos/dev/baseos.tar.gz

TARGET_TARCOMP	= -j
YUM		= $Vyum -c $(DLTMP)/yum.conf -y --disablerepo=* \
		  --enablerepo=install --enablerepo=updates \
		  --enablerepo=vpsadminos \
		  --installroot=$(INSTMP)
RPM		= $Vrpm $(VRPM) --root $(INSTMP)

define YUM_CONF
[main]
cachedir=$(DLTMP)/var/cache/yum/$(ARCH)/$(RELVER)
keepcache=0
debuglevel=2
logfile=$(DLTMP)/var/log/yum.log
exactarch=1
obsoletes=1
gpgcheck=1
plugins=1
installonly_limit=3
exclude=kernel*

[install]
name=install
enabled=1
gpgcheck=0
baseurl=$(BASEREPO)

[updates]
name=updates
enabled=1
gpgcheck=0
baseurl=$(UPDATEREPO)

[vpsadminos]
name=vpsadminos
enabled=1
gpgcheck=0
baseurl=$(VPSADMINOSREPO)
endef
export YUM_CONF

mktemps:
	$Vmkdir -p $(INSTMP) $(DLTMP)

baseos_download_relrpm:
	$Vcurl $(VCURL) -o $(DLTMP)/release.rpm $(RELRPM)

baseos_bootstrap:
	$Vmkdir -p $(INSTMP)/var/lib/rpm
	$(RPM) --initdb
	$(RPM) --nodeps -i $(DLTMP)/release.rpm
	$Vecho "$$YUM_CONF" > $(DLTMP)/yum.conf
	$Vmkdir -p $(DLTMP)/var/cache/yum $(DLTMP)/var/log
	$(YUM) groupinstall core

baseos_install_rpm:
	$(YUM) install `cat pkglist`

baseos_target_cleanup:
	$(YUM) clean all
	$Vrm -Rf $(INSTMP)/etc/ssh/ssh_host_*

baseos_target_pack:
	$Vtar $(TARGET_TARCOMP) $(VTAR) -cf $(TARGET_FILENAME) $(INSTMP)

baseos_yum:
	$(YUM) $(CMD)

baseos_chroot:
	$Vchroot $(INSTMP) /bin/bash

baseos_stats:
	$Vecho -e "Total size:\t`du -shx --apparent-size $(INSTMP)`"
	$Vecho -e "Packed size:\t`du -shx --apparent-size $(TARGET_FILENAME)`"

cleanup:
	$Vrm -Rf $(INSTMP) $(DLTMP)

ifeq ($(STEP),)
baseos_download_relrpm:	mktemps
baseos_bootstrap:	baseos_download_relrpm
baseos_install_rpm:	baseos_bootstrap
baseos_target_cleanup:	baseos_install_rpm
baseos_target_pack:	baseos_target_cleanup
cleanup:		
all:			baseos_target_pack
.DEFAULT_GOAL :=	all
endif

