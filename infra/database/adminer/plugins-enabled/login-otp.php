<?php
require_once('plugins/login-otp.php');

/** 
  * @param string decoded secret, e.g. base32_decode("SECRET")
  */
return new AdminerLoginOtp(
  $secret = base64_decode($_ENV['OTP_SECRET_B64'])
);