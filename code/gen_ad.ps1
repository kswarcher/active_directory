param(
    [parameter(Mandatory=$true)] $JSONFile,
    [int]$Undo
    )

function CreateADGroup(){

    param([parameter(Mandatory=$true)] $groupObject)

    $name = $groupObject.name

    New-ADGroup -name $name -GroupScope Global

}

function RemoveADGroup(){

    param([parameter(Mandatory=$true)] $groupObject)

    $name = $groupObject.name

    Remove-ADGroup -Identity $name -Confirm:$false

}


function CreateADUser(){

    param([parameter(Mandatory=$true)] $userObject)

    #Pull out name from JSON obj and then generate a first initial last name structure
    $name = $userObject.name
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).ToLower() 
    $samAccountName = $username
    $principalname = $username
    
    $password = $userObject.password
    #Actually create the AD user object
    New-ADUser -Name "$name" -GivenName $firstname -Surname $lastname -SamAccountName $samAccountName -userPrincipalName $principalname@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount

    foreach($group_name in $userObject.groups){

        
        try {
            Get-ADGroup -Identity "$group_name"
            Add-ADGroupMember -Identity $group_name -Members $username
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            Write-Warning "User $name NOT added to $group_name because it does not exist"
        }

    }

    # Add to local admin group
    if ($userObject.local_admin){
        #Add-LocalGroupMember -Group "Administrators" -Member "$Global:Domain\$username"
        net localgroup administrators  $Global:Domain\$username /add
    }


}


function RemoveADUser(){

    param([parameter(Mandatory=$true)] $userObject)

    $name = $userObject.name
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).ToLower() 
    $samAccountName = $username
    Remove-ADUser -Identity $samAccountName -Confirm:$false

}

function WeakenPasswordPolicy(){

secedit /export /cfg C:\Windows\Tasks\secpol.cfg
(Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0").replace("MaximumPasswordAge = 42", "MaximumPasswordAge = 365").replace("MinimumPasswordLength = 7", "MinimumPasswordLength = 0").replace("PasswordHistorySize = 24", "PasswordHistorySize = 0") | Out-File C:\Windows\Tasks\secpol.cfg
#(Get-Content C:\Windows\Tasks\secpol.cfg).replace("MaximumPasswordAge = 42", "MaximumPasswordAge = 365") | Out-File C:\Windows\Tasks\secpol.cfg
#(Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordHistorySize = 24", "PasswordHistorySize = 0") | Out-File C:\Windows\Tasks\secpol.cfg
#(Get-Content C:\Windows\Tasks\secpol.cfg).replace("MinimumPasswordLength = 7", "MinimumPasswordLength = 0") | Out-File C:\Windows\Tasks\secpol.cfg
secedit /configure /db C:\Windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
rm -force C:\Windows\Tasks\secpol.cfg -confirm:$false

}

function StrengthenPasswordPolicy(){

    secedit /export /cfg C:\Windows\Tasks\secpol.cfg
    (Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1").replace("MinimumPasswordLength = 0", "MinimumPasswordLength = 7") | Out-File C:\Windows\Tasks\secpol.cfg
    #(Get-Content C:\Windows\Tasks\secpol.cfg).replace("MaximumPasswordAge = 42", "MaximumPasswordAge = 365") | Out-File C:\Windows\Tasks\secpol.cfg
    #(Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordHistorySize = 24", "PasswordHistorySize = 0") | Out-File C:\Windows\Tasks\secpol.cfg
    #(Get-Content C:\Windows\Tasks\secpol.cfg).replace("MinimumPasswordLength = 0", "MinimumPasswordLength = 7") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db C:\Windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    rm -force C:\Windows\Tasks\secpol.cfg -confirm:$false
    
    }




 $json = (Get-Content $JSONFile | ConvertFrom-JSON)

$Global:Domain = $json.domain

if ( -not $Undo){

    WeakenPasswordPolicy

foreach ( $group in $json.groups){
    CreateADGroup $group
 }

 foreach ( $user in $json.users){
    CreateADUser $user
 }

}else{

    StrengthenPasswordPolicy

    foreach ( $user in $json.users){
        RemoveADUser $user
     }
    foreach ( $group in $json.groups){
        RemoveADGroup $group
     }
    
     

}