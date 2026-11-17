<#
.SYNOPSIS
    Decodes the payload of a JSON Web Token (JWT) and returns the claims as an object.

.DESCRIPTION
    Used in SC-300 Labs 2.2, 3.4 and 3.5. The token is NOT validated - this only reads
    the payload so you can see aud, appid, scp, roles and the other claims.
    Dot-source the file to get the function into your session:

        . .\ConvertFrom-Jwt.ps1
        ConvertFrom-Jwt -Token $token.access_token | Select-Object aud, appid, scp, roles, upn

.NOTES
    Windows PowerShell 5.1 and PowerShell 7 compatible.
#>

function ConvertFrom-Jwt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Token
    )
    process {
        $parts = $Token.Split('.')
        if ($parts.Count -lt 2) { throw 'This is not a JWT (expected header.payload.signature).' }

        # Base64URL -> Base64, then pad to a multiple of 4
        $payload = $parts[1].Replace('-', '+').Replace('_', '/')
        while ($payload.Length % 4) { $payload += '=' }

        $json   = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload))
        $claims = $json | ConvertFrom-Json

        # Add readable timestamps next to the Unix times
        foreach ($name in 'iat', 'nbf', 'exp') {
            if ($claims.PSObject.Properties[$name]) {
                $local = [DateTimeOffset]::FromUnixTimeSeconds([long]$claims.$name).LocalDateTime
                $claims | Add-Member -NotePropertyName "${name}Local" -NotePropertyValue $local
            }
        }
        $claims
    }
}
