<?php
header("Access-Control-Allow-Origin: *"); //for developping & testing purposes

// The AD9361 is not always iio:device1 (on Rev.C it is iio:device0 and
// iio:device1 is the xadc), so look the device up by name.
function ad9361_dev()
{
    foreach (glob('/sys/bus/iio/devices/iio:device*/name') as $name) {
        if (trim(file_get_contents($name)) == 'ad9361-phy') {
            return basename(dirname($name));
        }
    }
    return 'iio:device0';
}
$phy = '/sys/bus/iio/devices/'.ad9361_dev();
$phydbg = '/sys/kernel/debug/iio/'.ad9361_dev();

//set and return requested gain
if(isset($_GET['gain'])){
    $cmd = 'echo '.floatval($_GET['gain']).' >  '.$phy.'/out_voltage0_hardwaregain';
    exec($cmd);
}

if(isset($_GET['onair'])){
    $cmd = 'cat '.$phy.'/out_altvoltage1_TX_LO_powerdown';
    exec($cmd,$return);
    
    foreach( $return as & $value )
    {
    echo $value;
    }
}

if(isset($_GET['PTT'])){
    $Tx= $_GET['PTT'];
    if($Tx == "on")
    {
        // GPO manual mode (was set by watchconsoletx.sh, which is no longer started)
        $cmd = 'echo 0x26 0x10 > '.$phydbg.'/direct_reg_access';
        exec($cmd);
        $cmd = 'echo 0x27 0x10 > '.$phydbg.'/direct_reg_access';
        exec($cmd);
        $cmd = 'echo  0 >  '.$phy.'/out_altvoltage1_TX_LO_powerdown';
        exec($cmd);
    }
    else
    if($Tx == "off")
    {
        $cmd = 'echo 0x27 0x00 > '.$phydbg.'/direct_reg_access';
        exec($cmd);
        $cmd = 'echo  1 >  '.$phy.'/out_altvoltage1_TX_LO_powerdown';
        exec($cmd);
    }
    
}

//get status
//doo whatever we like here TBD
if(isset($_GET['status'])){
     // used in shell commands below: only allow plain identifiers like "" or "rcv"
     $source = preg_replace('/[^A-Za-z0-9_]/', '', $_GET['source']);
     
     $cmd = "/root/reportbitrate.sh ".$source;	
     exec($cmd,$stuff);	
     echo "{";

     echo '"bitrate": ';
     echo "[";
     $i=0;
     foreach( $stuff as & $value ) {
     echo $value;
     $i++;
     if( $i < count($stuff) ){
     echo ",";
     }
     }
     echo "]";
     
 $cmd = "/root/reportpid.sh ".$source;
     exec($cmd,$pid);
     echo ',';
     echo '"pid": ';
     echo "[";
     $i=0;
     foreach( $pid as & $value ) {	
     echo '"' . $value;
     switch($value) {

     case 0 : echo "(PAT)";break;
     case 17 : echo "(SDT)";break;
     case 256: echo  "(Video)";break;
     case 257 : echo  "(Audio)";break;
     case 4096 : echo  "(PMT)";break;
     case 8191 : echo  "(Null packets)";break;
    }
   
     echo '"';		
     $i++;
     if( $i < count($pid) ){
     echo ",";
     }
     }
     echo "]";
//end of PID Array

$i=0;
echo ',';
echo '"pcr": ';
echo "[";
     

     $cmd = "tail -n 200 /root/pcr".$source.".txt";
     exec($cmd,$pcrline);
     foreach( $pcrline as & $value ) {
         $arraypcr=explode(';',$value);	
        echo '"' . $arraypcr[7]/90 .'"';
        $i++;
     if( $i < count($pcrline) ){
     echo ",";
     }
     }  
     echo "]";

$i=0;

echo ',';
echo '"pcrlabel": ';
echo "[";
     

     foreach( $pcrline as & $value ) {
         $arraypcr=explode(';',$value);	
        echo '"' . $arraypcr[6]/90000 .'"';
        $i++;
     if( $i < count($pcrline) ){
     echo ",";
     }
     }  
     echo "]";

 //Name and provider
 $cmd = "/root/reportname.sh ".$source;
     
 echo ',';
echo '"name": "';
echo exec($cmd);
echo '"';

$cmd = "/root/reportprovider.sh ".$source;
echo ',';
echo '"provider": "';
echo exec($cmd);
echo '"';

//end of json
echo "}";
}	
	




?>
