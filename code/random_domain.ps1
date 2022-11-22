param( 
    [Parameter(Mandatory=$true)] $OutputJSONFile,
    [int]$num_users,
    [int]$num_groups,
    [int]$num_localAdmin
    )

#Getting data from files

$group_names = [System.Collections.ArrayList](Get-Content "data/group_names.txt")
$first_names = [System.Collections.ArrayList](Get-Content "data/first_names.txt")
$last_names = [System.Collections.ArrayList](Get-Content "data/last_names.txt")
$passwords = [System.Collections.ArrayList](Get-Content "data/passwords.txt")

##Making 10 random groups
$groups = @()
$users = @()

if ($num_users -eq 0){
    $num_users = 5
}
if ($num_groups -eq 0){
    $num_groups = 1
}


if ($num_localAdmin -ne 0){
    $local_admin_indexes = @()
    while(($local_admin_indexes | Measure-Object).Count -lt $num_localAdmin){

        $random_index = (Get-Random -InputObject (1..$num_users) | Where-Object{$local_admin_indexes -notcontains $_})
        $local_admin_indexes += $random_index
    }
}


for ( $i = 1; $i -le $num_groups; $i++){
$group_name = (Get-Random -InputObject $group_names )
$group = @{"name"="$group_name"}
$groups+= $group
$group_names.Remove($group_name)
}


##Making random users

for ( $i = 1; $i -le $num_users; $i++){
$first_name = (Get-Random -InputObject $first_names)
$last_name = (Get-Random -InputObject $last_names)
$password = (Get-Random -InputObject $passwords)
$new_user = @{
    "name"="$first_name $last_name"
    "password"="$password"
    "groups" = @( (Get-Random -InputObject $groups).name)
}

if($local_admin_indexes | Where {$_ -eq $i}){
    $new_user["local_admin"] = $true
}

$users+=$new_user
$first_names.Remove($first_name)
$last_names.Remove($last_name)
$passwords.Remove($password)

}


##Making the JSON

@{
"domain" = "xyz.com"
"groups"=$groups
"users"=$users
} | ConvertTo-JSON | Out-File $OutputJSONFile
