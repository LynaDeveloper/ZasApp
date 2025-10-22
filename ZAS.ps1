Clear-Host
$RandomNum = ''
$LastIDseen = 0 
$FirstStart = $true

$SUPABASE_URL = "https://gdyzwtuiyoslioetalxi.supabase.co"
$API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdkeXp3dHVpeW9zbGlvZXRhbHhpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEwNzE1MTYsImV4cCI6MjA3NjY0NzUxNn0.qszzJJfh9-Pn0ypUHc6ovRGBHKLKzaXu55WXg0bMHVM"
$TABLE = "messages"
# Se mantiene la URL base con concatenación
$URL_BASE = $SUPABASE_URL+"/rest/v1/"+$TABLE

$GlobalHeader = @{
    "apikey" = $API_KEY
    "Authorization" = "Bearer $API_KEY"
    "Content-Type" = "application/json"
    "Prefer" = "return=minimal"
}

0..4 | ForEach-Object {
    $RandomNum += Get-Random -Minimum 0 -Maximum 9
}

Write-Host "< Code : '$RandomNum' >"
$Code = Read-Host -Prompt "Introduce the Code to Continue -> "
if ($Code -ne $RandomNum) {
    Write-Error "Error: Incorrect Code"
    exit(1)
}
$usr = Read-Host -Prompt "Introduce your username -> "
$usrList = $usr.ToCharArray()

foreach ($i in $usrList) {
    if ([string]::IsNullOrWhiteSpace($i)) {
    Write-Error "Invalid Username (contains space or empty character)"
    exit(1)
    }
}
if ($usrList.Length -lt 3) {
    Write-Error "Invalid Username (must be at least 3 chars)"
    exit(1)
}
Write-Host "--- Connecting to ZAS Chat as @$usr ---" -ForegroundColor Yellow

# Ahora, el ciclo principal es solo un bloqueador de Read-Host
while ($true) {

    $msg = Read-Host -Prompt "@($usr) -> "
    
    if ([string]::IsNullOrWhiteSpace($msg)) {
        Write-Warning "Message Is Empty"
        continue
    }

    # Lógica de comandos
    if ( $msg -eq "/check" ) {
        
        # --- LÓGICA DE LECTURA DE MENSAJES (SOLO AQUÍ) ---

        # Construcción de la URL de lectura usando la concatenación original
        $URL_BASE_AUTH_QUERY = $URL_BASE+"?apikey="+$API_KEY
        
        if ($FirstStart) {
            # Primera carga, trae los últimos 10 mensajes
            $URL_LECTURA = $URL_BASE_AUTH_QUERY+"&order=id.desc&limit=10"
        } else {
            # Cargas subsiguientes, solo trae los nuevos (después del último visto)
            $URL_LECTURA = $URL_BASE_AUTH_QUERY+"&id=gt."+$LastIDseen+"&order=id.asc" 
        }

        try {
            $NuevosMensajes = Invoke-RestMethod -Uri $URL_LECTURA -Method Get -Headers $GlobalHeader
            
            if ($FirstStart) {
                # En la primera carga, ordenamos por ID descendente
                $NuevosMensajes = $NuevosMensajes | Sort-Object -Property id -Descending
            }
        } catch {
            Write-Error "Error while reading menssages: $($_.Exception.Message)"
            Start-Sleep -Seconds 1 # Espera corta en caso de error
            continue
        }
        
        if ($NuevosMensajes.Count -gt 0) {
            if ($FirstStart) {
                Write-Host "--- LAST MESSAGES ---" -ForegroundColor Yellow
            } else {
                Write-Host "--- NEW MESSAGES ---" -ForegroundColor Yellow
            }
            
            $MaxID = 0  # Para rastrear el ID más alto
            
            foreach ($Mensaje in $NuevosMensajes) {
                # Convertir la fecha UTC a hora local
                $MsgTime = ($Mensaje.date)
                $TimeStr = $MsgTime.ToString("HH:mm:ss")
                
                if ($Mensaje.usr -eq $usr) {
                    Write-Host "[$TimeStr] YOU -> $($Mensaje.msg)" -ForegroundColor Cyan
                } else {
                    Write-Host "[$TimeStr] $($Mensaje.usr) -> $($Mensaje.msg)" -ForegroundColor Green
                }
                
                # Actualizamos el ID más alto visto
                if ($Mensaje.id -gt $MaxID) {
                    $MaxID = $Mensaje.id
                }
            }
            
            # Actualizamos LastIDseen con el ID más alto encontrado
            if ($MaxID -gt $LastIDseen) {
                $LastIDseen = $MaxID
            }
        } elseif (-not $FirstStart) {
            Write-Host "No new messages." -ForegroundColor Yellow
        }
        
        $FirstStart = $false
        
        # --- FIN LÓGICA DE LECTURA ---
        
        continue # Vuelve a pedir input después de la lectura
        
    } elseif ($msg -eq '/history') {
        Write-Host "Fetching full chat history..." -ForegroundColor Yellow
        
        # Construir URL para obtener todo el historial
        $URL_HISTORY = $URL_BASE+"?apikey="+$API_KEY+"&order=id.asc"
        
        try {
            $HistorialMensajes = Invoke-RestMethod -Uri $URL_HISTORY -Method Get -Headers $GlobalHeader
            
            if ($HistorialMensajes.Count -gt 0) {
                Write-Host "--- CHAT HISTORY ---" -ForegroundColor Yellow
                foreach ($Mensaje in $HistorialMensajes) {
                    # Convertir la fecha UTC a hora local
                    $MsgTime = [DateTime]::Parse($Mensaje.created_at).ToLocalTime()
                    $TimeStr = $MsgTime.ToString("HH:mm:ss")
                    
                    if ($Mensaje.usr -eq $usr) {
                        Write-Host "[$TimeStr] YOU -> $($Mensaje.msg)" -ForegroundColor Cyan
                    } else {
                        Write-Host "[$TimeStr] $($Mensaje.usr) -> $($Mensaje.msg)" -ForegroundColor Green
                    }
                }
                Write-Host "--- END OF HISTORY ---" -ForegroundColor Yellow
            } else {
                Write-Host "No messages in history." -ForegroundColor Yellow
            }
        } catch {
            Write-Error "Error fetching history: $($_.Exception.Message)"
            Start-Sleep -Seconds 1
            continue
        }

        continue
        
    } elseif ($msg -eq '/exit') {
        Write-Host "Thanks For Using ZAS!" -ForegroundColor Green
        exit(0)
    } elseif ($msg -eq '/version') {
        Write-Host "ZAS is using its 1.0 Version"
        continue
    } elseif ( $msg -eq '/help' -or $msg[0] -eq '/') {
        Write-Host "Here Are The Commands You Can Use:"
        Write-Host "/exit - Exit The Program"
        Write-Host "/help - Show This Help Message"
        Write-Host "/check - Check for new messages and display them (Required for updates)"
        Write-Host "/history - Fetch and display the full chat history"
        Write-Host "/version - Shows the ZAS version"
        continue
    }

    
    # Lógica de envío de mensaje (POST)
    $body = @{
        usr = $usr
        msg = $msg
    } | ConvertTo-Json
    
    # Construcción de la URL de escritura usando la concatenación original
    $URL_ESCRITURA = $URL_BASE+"?apikey="+$API_KEY

    try {
        Invoke-RestMethod -Uri $URL_ESCRITURA -Method Post -Headers $GlobalHeader -Body $body | Out-Null
    } catch {
        Write-Error "Error while sending menssages (POST): $($_.Exception.Message)"
    }
    
}

