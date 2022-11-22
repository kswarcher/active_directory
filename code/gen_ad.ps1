#Getting the user inputs in the command, specify JSON file to read from and if the user wants to undo the AD
param(

    [parameter(Mandatory=$true)] $JSONFile,
    [int]$Undo

    )

#Creating the AD groups
function CreateADGroup(){

    param([parameter(Mandatory=$true)] $groupObject)

    $name = $groupObject.name

    New-ADGroup -name $name -GroupScope Global

}

#Removing the AD groups
function RemoveADGroup(){

    param([parameter(Mandatory=$true)] $groupObject)

    $name = $groupObject.name

    Remove-ADGroup -Identity $name -Confirm:$false

}

#Creating an AD user
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



        #Making sure the user got added    
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
        Add-LocalGroupMember -Group Administrators -Member $Global:Domain\$username
        #net localgroup administrators  $Global:Domain\$username /add
    }


}


#Removing an AD user
function RemoveADUser(){

    param([parameter(Mandatory=$true)] $userObject)

    $name = $userObject.name
    $firstname, $lastname = $name.Split(" ")
    $username = ($firstname[0] + $lastname).ToLower() 
    $samAccountName = $username
    Remove-ADUser -Identity $samAccountName -Confirm:$false

}

#Making the password policy less secure, but easier to work with
function WeakenPasswordPolicy(){

    secedit /export /cfg C:\Windows\Tasks\secpol.cfg
    (Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0").replace("MaximumPasswordAge = 42", "MaximumPasswordAge = 365").replace("MinimumPasswordLength = 7", "MinimumPasswordLength = 0").replace("PasswordHistorySize = 24", "PasswordHistorySize = 0") | Out-File C:\Windows\Tasks\secpol.cfg
    #(Get-Content C:\Windows\Tasks\secpol.cfg).replace("MaximumPasswordAge = 42", "MaximumPasswordAge = 365") | Out-File C:\Windows\Tasks\secpol.cfg
    #(Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordHistorySize = 24", "PasswordHistorySize = 0") | Out-File C:\Windows\Tasks\secpol.cfg
    #(Get-Content C:\Windows\Tasks\secpol.cfg).replace("MinimumPasswordLength = 7", "MinimumPasswordLength = 0") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db C:\Windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    Remove-Item C:\Windows\Tasks\secpol.cfg -Force -Confirm:$False

}

#Making the password policy stronger
function StrengthenPasswordPolicy(){

    secedit /export /cfg C:\Windows\Tasks\secpol.cfg
    (Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1").replace("MinimumPasswordLength = 0", "MinimumPasswordLength = 7") | Out-File C:\Windows\Tasks\secpol.cfg
    #(Get-Content C:\Windows\Tasks\secpol.cfg).replace("MaximumPasswordAge = 42", "MaximumPasswordAge = 365") | Out-File C:\Windows\Tasks\secpol.cfg
    #(Get-Content C:\Windows\Tasks\secpol.cfg).replace("PasswordHistorySize = 24", "PasswordHistorySize = 0") | Out-File C:\Windows\Tasks\secpol.cfg
    #(Get-Content C:\Windows\Tasks\secpol.cfg).replace("MinimumPasswordLength = 0", "MinimumPasswordLength = 7") | Out-File C:\Windows\Tasks\secpol.cfg
    secedit /configure /db C:\Windows\security\local.sdb /cfg C:\Windows\Tasks\secpol.cfg /areas SECURITYPOLICY
    Remove-Item C:\Windows\Tasks\secpol.cfg -Force -Confirm:$Falsese
    
    }



#Getting info from the json file for person info
$json = (Get-Content $JSONFile | ConvertFrom-JSON)

$Global:Domain = $json.domain

#Determining if the AD needs to be set up or torn down
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
