func sendACCode(id: String) {
    
    var modeCode: Int
    var tempAdj: Int
    var tempCode: Int = 0
    
    switch modeSelect {
    case Mode.Cold: modeCode = 0x8820 * 256
    case Mode.Fan: modeCode = 0x8822 * 256
    case Mode.Dry: modeCode = 0x8821 * 256
    case Mode.Saver: modeCode = 0x8826 * 256
        
    }
    
    switch fanSelect {
    case FanSpeed.Low: tempAdj = 0
    case FanSpeed.Medium: tempAdj = 2
    case FanSpeed.High: tempAdj = 4
        
    }
    
    if (tempSelect >= 60 && tempSelect < 75) {
        
        tempCode = 16 * (tempSelect - 60 + 1)
        
    }
        
    else if (tempSelect > 74 && tempSelect <= 86) {
        
        tempCode = 16 * (tempSelect - 75 + 1) - 8
        
    }
    
    let sum = modeCode + tempCode + tempAdj
    
    var sumString = String(sum, radix: 16).uppercaseString
    
    var checkSum = 0
    
    for i in 0 ..< sumString.characters.count {
        
        let index = sumString.startIndex.advancedBy(i)
        
        let char = sumString[index]
        
        let hex = "0x" + String(char)
        
        let value = Int(strtoul(hex, nil, 16))
        
        checkSum += value
        
    }
    
    let hexCheckSum = String(checkSum, radix: 16).uppercaseString
    
    if let lastChar = hexCheckSum.characters.last {
        
        sumString += String(lastChar)
        
        sendCode(id, arg: sumString)
    }
    
}

func sendCode(id: String, arg: String) {
    var urlString = "http://" + id + ".local/"
    
    urlString += "code?ac" + "=" + arg
    
    print(urlString)
    
    let url = NSURL(string: urlString)
    let urlRequest = NSMutableURLRequest(URL: url!)
    
    let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
    
    configuration.timeoutIntervalForRequest = 5
    
    let session = NSURLSession(configuration: configuration)
    
    let dataSession = session.dataTaskWithRequest(urlRequest)
    
    dataSession.resume()
    
}