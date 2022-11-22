#Getting the output JSON file, number of users, groups, and local admins
param( 
    [Parameter(Mandatory=$true)] $OutputJSONFile,
    [int]$UserAmount,
    [int]$GroupAmount,
    [int]$LocalAdminAmount
    )

#Getting data from files

$group_names = [System.Collections.ArrayList](Get-Content "data/group_names.txt")
$first_names = [System.Collections.ArrayList](Get-Content "data/first_names.txt")
$last_names = [System.Collections.ArrayList](Get-Content "data/last_names.txt")
$passwords = [System.Collections.ArrayList](Get-Content "data/passwords.txt")

#Setting an amount of users and groups if not given
$groups = @()
$users = @()

if ($UserAmount -eq 0){
    $UserAmount = 5
}
if ($GroupAmount -eq 0){
    $GroupAmount = 1
}

#Making some of the users become local admins
if ($LocalAdminAmount -ne 0){
    $local_admin_indexes = @()
    while(($local_admin_indexes | Measure-Object).Count -lt $num_localAdmin){

        $random_index = (Get-Random -InputObject (1..$UserAmount) | Where-Object{$local_admin_indexes -notcontains $_})
        $local_admin_indexes += $random_index
    }
}

#Making random groups
for ($i = 1; $i -le $GroupAmount; $i++){
$group_name = (Get-Random -InputObject $group_names )
$group = @{"name"="$group_name"}
$groups+= $group
$group_names.Remove($group_name)
}


#Making random users
for ( $i = 1; $i -le $UserAmount; $i++){
$first_name = (Get-Random -InputObject $first_names)
$last_name = (Get-Random -InputObject $last_names)
$password = (Get-Random -InputObject $passwords)
$new_user = @{
    "name"="$first_name $last_name"
    "password"="$password"
    "groups" = @( (Get-Random -InputObject $groups).name)
}

#Assigning users to be admins
if($local_admin_indexes | Where {$_ -eq $i}){
    $new_user["local_admin"] = $true
}
#Adding users credentials
$users+=$new_user
$first_names.Remove($first_name)
$last_names.Remove($last_name)
$passwords.Remove($password)

}


#Making the JSON
@{
"domain" = "xyz.com"
"groups"=$groups
"users"=$users
} | ConvertTo-JSON | Out-File $OutputJSONFile
