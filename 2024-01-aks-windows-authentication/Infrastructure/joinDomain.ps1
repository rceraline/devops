$username = "useradmin";
$password = "JCH4rqwgvh3xqcqbf"
$domain = "mycompany.local";

$joinCred = New-Object pscredential -ArgumentList ([pscustomobject]@{  
    UserName = $username;
    Password = (ConvertTo-SecureString -String $password -AsPlainText -Force)[0] 
});
    
Add-Computer -Domain $domain -Credential $joinCred -Force -Restart