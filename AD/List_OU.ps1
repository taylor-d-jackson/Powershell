function Get-OUList {
  Get-ADOrganizationalUnit -Filter * -Properties * -SearchBase "OU=,OU=,DC=,DC=" | Select-Object -Property Name, DistinguishedName | Format-Table -Auto
}
