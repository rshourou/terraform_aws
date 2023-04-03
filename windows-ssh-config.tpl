add-content -path C:/Users/12368/.ssh/config -value @'

Host ${hostname}
 Hostname ${hostname}
 User ${user}
 IdentityFile ${identityfile}

'@