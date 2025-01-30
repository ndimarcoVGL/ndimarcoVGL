#!/usr/bin/env php
<?php

//Author: Nic DiMarco
//Purpose: This script will monitor the cpu temperature of a pfsense appliance, and will send a push notification via the Pushover API if the temperature exceeds the max_temp variable

require_once("notices.inc");
require_once("util.inc");

//debugging
error_reporting(E_ALL);
ini_set("display_errors", 1);
ini_set("log_errors", 1);
ini_set("error_log", "/tmp/temp_alert.log");

error_log("=== script begin ===");
$alarm_temp = 58; //set the threshold temperature for the "too hot" condition
$sentinel = '/tmp/temp_alarm';

//pushover API credentials
$pushover_user_key = 'user_key'; //replace with your Pushover user key
$pushover_api_token = 'api_token'; //replace with your Pushover API token

//function to send notifications via Pushover
function send_pushover_notification($message) {
    global $pushover_user_key, $pushover_api_token;

    $url = "https://api.pushover.net/1/messages.json";
    $data = [
        'user' => $pushover_user_key,
        'token' => $pushover_api_token,
        'message' => $message,
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

    $response = curl_exec($ch);
    curl_close($ch);

    //log the response from Pushover
    error_log("Pushover response: " . $response);
}

//discover sensors and auto-select the hottest one  
$sensor = isset($argv[1]) ? trim($argv[1]) : null;
if (empty($sensor)) {
    error_log("no sensor specified, trying to auto-detect");
    exec('sysctl -a | grep temperature | awk -F: \'{sub("C","",$2); if($2>max_t){max_t=$2;v=$1}} END {print v}\'', $output, $retval);
    $sensor = $output[0] ?? null;
    unset($output);
    if (empty($sensor)) {
        error_log("failed to auto-detect a temperature sensor");
        exit();
    } else {
        error_log("detected sensor: {$sensor}");
    }
} else {
    error_log("using sensor {$sensor} supplied at the commandline");
}

//check the temperature
exec("sysctl -n " . escapeshellarg($sensor), $output, $retval);
if (($retval == 0) && (count($output))) {
    $temp = $output[0] ? intval($output[0]) : -1;
    
    //Always send a notification with the current temperature (uncomment the next 3 lines for testing)
    //$msg = "Current temperature of {$sensor} is {$temp}C";
    //error_log("Sending notification: {$msg}");
    //send_pushover_notification($msg);

    //check if temperature exceeds the threshold (too hot)
    if ($temp >= $alarm_temp) {
        $msg = "ALERT: Temperature of {$sensor} has exceeded the threshold! Current temperature: {$temp}C";
        error_log("Sending ALERT notification: {$msg}");
        send_pushover_notification($msg);
    }
} else {
    error_log("sensor {$sensor} returned no data");
}

error_log("=== script end ===" . "\n");

?>
