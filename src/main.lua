Encrypt = require 'encrypt'
local http = require("socket.http")
local os = require('os')
local io = require('io')

function Sleep(n)
    os.execute("sleep " .. n)
end


local function loadConfig()
    local username, password
    local file = io.open("my.conf", "r")
    if file then
        username = file:read()
        password = file:read()
        file:close()
    end
    assert(username, "username not found")
    assert(password, "password not found")
    return username, password
end

local char_to_hex = function(c)
    return string.format("%%%02X", string.byte(c))
  end
  

local function urlencode(url)
    if url == nil then
        return
    end
    url = url:gsub("\n", "\r\n")
    url = url:gsub("([^%w ])", char_to_hex)
    url = url:gsub(" ", "+")
    return url
end
  
  
local function login(username, password)
    -- get portal page
    local f = assert(io.popen("curl -s http://www.baidu.com"))
    local resp = f:read("*a")
    -- <script>top.self.location.href=''</script>
    -- local resp = "<script>top.self.location.href='http://172.18.18.60:8080/eportal/index.jsp?wlanuserip=7fa57bf204de38da405683f70baf7077&wlanacname=cf9cf04d33d5c3f519f32ce800fc6b26&ssid=&nasip=21aea9e1c34fe0bfecaa6d4544af21c6&snmpagentip=&mac=4b81fcbe9fe5628025afb76b24acf3a9&t=wireless-v2&url=709db9dc9ce334aad9f3cf534a58c238a63df9f3a78ce15e&apmac=&nasid=cf9cf04d33d5c3f519f32ce800fc6b26&vid=7cf19e8d39640eff&port=0420db3da20109a5&nasportid=5b9da5b08a53a540c50f09ff9314858f52af17bbb8808337e1f19a979c9d4d2309cc94139ab28b94'</script>"
    local url=string.match(resp, "<script>top.self.location.href=\'(.-)\'</script>")
    
    if not url then
        print("Already Connect")
        return
    end
    print("Try to Login")
    -- mac
    local mac = string.match(url, "mac=(.-)&")
    print("mac: ", mac)

    -- portal_ip, query_string
    local portal_ip, query_string = string.match(url, "http://(.-)/eportal/index.jsp%?(.-)$")
    print("portal_ip: ", portal_ip)
    query_string = urlencode(query_string)
    print("query_string: ", query_string)

    -- encrypt password
    local encrypt_password = Encrypt.Encrypt_Pass(string.format("%s>%s", password, mac))
    print("encrypt_password: ", encrypt_password)

    -- login
    local login_url = "http://" .. portal_ip .. "/eportal/InterFace.do?method=login"
    local body = string.format("userId=%s&password=%s&service=&queryString=%s&passwordEncrypt=true", username, encrypt_password, query_string)
    local curl = string.format("curl -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'Accept: */*' -H 'User-Agent: hust-network-login' -X POST -d '%s' '%s'", body, login_url)
    -- print(curl)

    local resp, flag, status = os.execute(curl)
    print("login success")
    return true
end


local username, password = loadConfig()
while true do
    login(username, password)
    Sleep(10)
end
