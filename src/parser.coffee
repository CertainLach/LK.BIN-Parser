fs=require 'fs'

console.log 'lk.bin parser'
console.log 'By F6CF and VITEK999'

start=do (new Date).getTime

headers=
               # CMD                 ARGC ARG1 ARG2 ARG3  
               #  FF   00   00   00   05   FF   98   06   04   01
    ili_9806_e:[0xFF,0x00,0x00,0x00,0x05,0xFF,0x98,0x06,0x04,0x01]
               #  FF   00   00   00   03   80   09   01
    otm_8009_a:[0xFF,0x00,0x00,0x00,0x03,0x80,0x09,0x01]
               #  C0   00   00   00   05   00   58   00   14   16
    otm_f:     [0xC0,0x00,0x00,0x00,0x05,0x00,0x58,0x00,0x14,0x16]
               #  FF   00   00   00   03   12   83   01
    otm_1283_a:[0xFF,0x00,0x00,0x00,0x03,0x12,0x83,0x01]
               #  FF   00   00   00   03   96   05   01
    otm_9605_a:[0xFF,0x00,0x00,0x00,0x03,0x96,0x05,0x01]
               #  FF   00   00   00   03   96   08  01
    otm_9608_a:[0xFF,0x00,0x00,0x00,0x03,0x96,0x08,0x01]
               #  B9   00   00   00   03   FF   83   94
    hx_8394:   [0xB9,0x00,0x00,0x00,0x03,0xFF,0x83,0x94]
               #  B9   00   00   00   03   FF   83   92
    hx_8392:   [0xB9,0x00,0x00,0x00,0x03,0xFF,0x83,0x92]              
               #  FF   00   00   00   03   98   81   03
    ili_9881_c:[0xFF,0x00,0x00,0x00,0x03,0x98,0x81,0x03]

class FoundHeader 
    constructor: (@name,@offset,@hex)->
    toString: -> return "Header of #{@name} on 0x#{@offset.toString 16}"
    getEnd: ->@offset+@hex.length-(@hex.length-8)
    
toHex=(int)->
    return undefined if int==undefined #Should never happen
    a=int.toString 16
    a="0"+a if a.length==1
    return "0x#{a}"

fs.readFile 'lk.bin', (err,file)->
    throw err if err
    finish=do (new Date).getTime
    console.log "fs.readFile took #{finish-start} ms"
    console.log "Binary size is #{file.length}"
    
    console.log 'Starting search of headers...'
    
    foundHeaders=[]
    
    for i in [0..file.length]
        if i%10000==0
            #     i     proc
            #     size  100
            #     proc=i*100/size
            process.stdout.write "Processed #{Math.round(i*100/file.length)}%\r"
        byte = (sym)->file[i+sym]
        checkHeader = (header)->
            correct = true
            for h in [0..header.length-1]
                if i+h>file.length-1
                    return false
                if file[i+h] != header[h]
                    #console.log file[i+h],header[h]
                    correct = false
            return correct
                
            
        for header of headers
            found=checkHeader headers[header]
            if found
                found=new FoundHeader header,i,headers[header]
                console.log '\n'+found
                foundHeaders.push found
    
    console.log "\nTotal #{foundHeaders.length} headers found"
    
    id=0
    hid=0
    foundHeaders.forEach (header)->
        hid++;
        out="";
        console.log "Processing header for #{header.name} (from 0x#{header.offset.toString 16} to 0x#{header.getEnd().toString 16})\n\n\n\n"
        processStart=do (new Date).getTime
        processed=0
        offset=do header.getEnd
        finish=false
        printOffset = (str)->
            console.log "0x#{offset.toString 16}:  #{str}"
        skip = (count)->
            offset+=count
        read = (count)->
            result=[]
            k=offset
            for j in [0..count-1]
                result.push file[k+j]
            result
        skip 64
        args=[]
        for n in [header.hex[4]+2..header.hex.length-1]
            args.push header.hex[n]
        args=args.map toHex
        out+= "{#{toHex header.hex[0]}, #{header.hex[4]}, {#{args.join ','}}},\n"
        while !finish||offset<file.length
            data=read 8
            if (data[4]==0)&&((toHex data[0])!='0x29')&&((toHex data[0])!='0x11') #TODO: Implement a better way to detect end of table
                out+="{REGFLAG_END_OF_TABLE, 0x00, {}}\n"
                processEnd=do (new Date).getTime
                console.log "Table #{hid} for #{header.name} processed in #{processEnd-processStart} ms"
                finish=true
                break
            id++
            args=[]
            for n in [offset+3+1+1..offset+3+data[4]+1]
                args.push file[n]
            args=args.map toHex
            out+= "{#{toHex data[0]}, #{data[4]}, {#{args.join ','}}},\n"
            #out+="{#{toHex data[0]}}123,\n"
            skip 8+64
            finish=true
            #skip 5
            #skip 66
        fs.writeFileSync header.name+'.'+hid+'.c',out
            
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
