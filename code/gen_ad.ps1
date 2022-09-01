param([parameter(Mandatory=$true)] $JSONFile)

function CreateADGroup(){

    param([parameter(Mandatory=$true)] $groupObject)

    $name = $groupObject.name

    New-ADGroup -name $name -GroupScope Global

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

}


 $json = (Get-Content $JSONFile | ConvertFrom-JSON)

$Global:Domain = $json.domain

foreach ( $group in $json.groups){

    CreateADGroup $group
 }

 foreach ( $user in $json.users){

    CreateADUser $user

 }
