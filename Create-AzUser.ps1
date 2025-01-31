param ($Name, $Surname, $Department)

#--- PASSWORD GENERATOR ------#
# Define the character sets
$lowercase = 'abcdefghijklmnopqrstuvwxyz'
$uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
$numbers = '0123456789'
$special = '!@#$%^&*()_+-=[]{}|;:,.<>?'

# Combine all character sets
$allChars = $lowercase + $uppercase + $numbers + $special

# Initialize the password variable
$password = ''

# Ensure each type of character is included at least once
$password += $lowercase | Get-Random -Count 1
$password += $uppercase | Get-Random -Count 1
$password += $numbers | Get-Random -Count 1
$password += $special | Get-Random -Count 1

# Generate the remaining characters randomly
for ($i = 1; $i -le 6; $i++) {
    $password += $allChars | Get-Random -Count 1
}

# Shuffle the password to ensure randomness
$password = ($password.ToCharArray() | Get-Random -Count $password.Length) -join ''

# Ensure the password is exactly 10 characters long
$password = $password.Substring(0, 10)
#------ END OF PASSWORD GENERATOR ------#

#--- CONNECT TO MICROSOFT GRAPH ------#
# Configuration
$ClientId     = "ClientID"
$TenantId     = "TenantID"
$ClientSecret = "Value"

# Convert the client secret to a secure string
$ClientSecretPass = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force

# Create a credential object using the client ID and secure string
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $ClientSecretPass

try {
# Connect to Microsoft Graph with Client Secret
Write-Output "Connecting To Microsoft Entra ID"
Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential -NoWelcome

# Set Password Profile
$PasswordProfile = @{
    Password = $password
    ForceChangePasswordNextSignIn = $true
}

# Define User Properties
$defaultDomain = (Get-MgDomain | Where-Object { $_.IsDefault -eq 'True' }).id
$givenname     = $Name
$surname       = $Surname
$department    = $Department
$displayName   = $givenname + " $surname"
$mailname      = $givenname + ".$surname"
$upn           = "$mailname@$defaultDomain"


# Check if user already exists
$userExists = Get-MgUser -Filter "userPrincipalName eq '$upn'"

if ($userExists) {
    Write-Output "User with UPN $upn already exists."
} else {

    New-MgUser -DisplayName "$displayName" -PasswordProfile $PasswordProfile -AccountEnabled:$true -UserPrincipalName "$upn" -GivenName $givenname -Surname $surname -MailNickname "$mailname" -Department "$department" | Out-Null
    Write-Output "User "$upn" created successfully."
    Write-Output "-------------------------"
    Write-Output "Default Domain: $defaultDomain"
    Write-Output "Givename: $givenname"
    Write-Output "Surname: $surname"
    Write-Output "Department: $department"
    Write-Output "DisplayName: $displayName"
    Write-Output "MailName: $mailname"
    Write-Output "Userprincipalname: $upn"
    Write-Output "Password: $password"
}

    Disconnect-MgGraph | Out-Null

}
catch {
    
    Write-Output $_.Exception.Message
}