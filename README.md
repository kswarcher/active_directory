# Active Directory Setup

## 01 Install DC

1. use `scconfig` to:
    - Change the hostname
    - Change the IP address to static
    - Change the DNS server to our own IP address

2. Install the Active Directory Windows Feature

```shell
Install-WindwosFeature AD-Domain-Services -IncludeManagementTools
```