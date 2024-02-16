$certificate=New-SelfSignedCertificate –Subject mywebsite.com -CertStoreLocation Cert:\CurrentUser\My
$password = ConvertTo-SecureString -String "p@ssw0rd" -Force -AsPlainText
Export-PfxCertificate -Cert $certificate -FilePath "C:\certificates\mywebsite_certificate.pfx" -Password $password
