<?php
include_once($_SERVER['DOCUMENT_ROOT'] . "/data/connect.php");
require_once($_SERVER['DOCUMENT_ROOT'] . "/vendor/autoload.php");
header('Content-Type: application/json');
$raw = file_get_contents('php://input');
file_put_contents(__DIR__ . '/debug.log', $raw . PHP_EOL, FILE_APPEND);
$data = json_decode($raw, true);
$restart = false;
$userid_raw_in = (isset($_SESSION['userid']) && trim((string) $_SESSION['userid']) !== '') ? $_SESSION['userid'] : ((isset($data['mobile']) && trim($data['mobile']) !== '') ? $data['mobile'] : '');
$username_raw_in = (isset($_SESSION['username']) && trim((string) $_SESSION['username']) !== '') ? $_SESSION['username'] : ((isset($data['name']) && trim($data['name']) !== '') ? $data['name'] : '');
$password_raw_in = (isset($_SESSION['password']) && trim((string) $_SESSION['password']) !== '') ? $_SESSION['password'] : ((isset($data['password']) && trim($data['password']) !== '') ? $data['password'] : '');
$birthday_raw_in = (isset($_SESSION['birthday']) && trim((string) $_SESSION['birthday']) !== '') ? $_SESSION['birthday'] : ((isset($data['birth']) && trim($data['birth']) !== '') ? $data['birth'] : '');
$gender_raw_in = (isset($_SESSION['gender_code']) && trim((string) $_SESSION['gender_code']) !== '') ? $_SESSION['gender_code'] : ((isset($data['gender']) && trim($data['gender']) !== '') ? $data['gender'] : '');
$telecom_raw_in = (isset($_SESSION['mobileco']) && trim((string) $_SESSION['mobileco']) !== '') ? $_SESSION['mobileco'] : ((isset($data['selectedCarrier']) && trim($data['selectedCarrier']) !== '') ? $data['selectedCarrier'] : '');
$isMvno_raw = (!empty($data['isMvno'])) ? 1 : 0;
$account_raw_in = (isset($_SESSION['account']) && trim((string) $_SESSION['account']) !== '') ? $_SESSION['account'] : ((isset($data['account']) && trim($data['account']) !== '') ? $data['account'] : '');
$bank_raw_in = (isset($_SESSION['bank']) && trim((string) $_SESSION['bank']) !== '') ? $_SESSION['bank'] : ((isset($data['bank']) && trim($data['bank']) !== '') ? $data['bank'] : '');
$userid_in_norm = preg_replace('/\D+/', '', (string) $userid_raw_in);
$birthday_in_norm = preg_replace('/\D+/', '', (string) $birthday_raw_in);
$gender_in_norm = (string) $gender_raw_in;
/*
$restart = false;
$userid_raw_in = (isset($data['mobile']) && trim($data['mobile']) !== '') ? $data['mobile'] : (isset($_SESSION['userid']) ? $_SESSION['userid'] : '');
$username_raw_in = (isset($data['name']) && trim($data['name']) !== '') ? $data['name'] : (isset($_SESSION['username']) ? $_SESSION['username'] : '');
$password_raw_in = (isset($data['password']) && trim($data['password']) !== '') ? $data['password'] : (isset($_SESSION['password']) ? $_SESSION['password'] : '');
$birthday_raw_in = (isset($data['birth']) && trim($data['birth']) !== '') ? $data['birth'] : (isset($_SESSION['birthday']) ? $_SESSION['birthday'] : '');
$gender_raw_in = (isset($data['gender']) && trim($data['gender']) !== '') ? $data['gender'] : (isset($_SESSION['gender_code']) ? $_SESSION['gender_code'] : '');
$telecom_raw_in = (isset($data['selectedCarrier']) && trim($data['selectedCarrier']) !== '') ? $data['selectedCarrier'] : (isset($_SESSION['mobileco']) ? $_SESSION['mobileco'] : '');
$isMvno_raw = (!empty($data['isMvno'])) ? 1 : 0;
$account_raw_in = (isset($data['account']) && trim($data['account']) !== '') ? $data['account'] : (isset($_SESSION['account']) ? $_SESSION['account'] : '');
$bank_raw_in = (isset($data['bank']) && trim($data['bank']) !== '') ? $data['bank'] : (isset($_SESSION['bank']) ? $_SESSION['bank'] : '');
$userid_in_norm = preg_replace('/\D+/', '', (string) $userid_raw_in);
$birthday_in_norm = preg_replace('/\D+/', '', (string) $birthday_raw_in);
$gender_in_norm = (string) $gender_raw_in;
*/
if ($gender_in_norm !== '1' && $gender_in_norm !== '2') {
	$gender_in_norm = '';
}
$userid = mysqli_real_escape_string($con, $userid_in_norm);
$username = mysqli_real_escape_string($con, (string) $username_raw_in);
$password = mysqli_real_escape_string($con, (string) $password_raw_in);
$birthday = mysqli_real_escape_string($con, $birthday_in_norm);
$gender = mysqli_real_escape_string($con, $gender_in_norm);
$telecom = mysqli_real_escape_string($con, (string) $telecom_raw_in);
$isMvno = $isMvno_raw ? 1 : 0;
$reg_dt = date('Y-m-d H:i:s');
$account = mysqli_real_escape_string($con, (string) $account_raw_in);
$bank = mysqli_real_escape_string($con, (string) $bank_raw_in);
$uri_path = isset($_SERVER['REQUEST_URI']) ? parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) : '';
if ($uri_path !== '' && strpos($uri_path, '/account/restart') !== false) {
	$restart = true;
} elseif (isset($_SERVER['HTTP_REFERER']) && strpos((string) $_SERVER['HTTP_REFERER'], 'restart') !== false) {
	$restart = true;
} elseif (isset($data['mode']) && $data['mode'] === 'restart') {
	$restart = true;
} elseif (!empty($data['restart'])) {
	$restart = true;
} elseif (!empty($_SESSION['restart'])) {
	$restart = true;
}
if ($userid === '' || $password === '') {
	echo json_encode(['result' => 'fail', 'error' => '필수 값 누락']);
	//mysqli_close($con);
	exit;
}
$existing = $con->query( "SELECT * FROM `users` WHERE `userid` = '" . $userid . "' LIMIT 1");
$hasUser = ($existing && mysqli_num_rows($existing) > 0) ? true : false;
$existingRow = $hasUser ? mysqli_fetch_assoc($existing) : null;
$result = true;
if ($hasUser) {
	$tripleMatch = ($birthday !== '' && $username !== '' && $gender !== '' && $existingRow['birthday'] === $birthday && $existingRow['username'] === $username && $existingRow['gender'] === $gender);
	$nameBirthMatch = ($birthday !== '' && $username !== '' && $existingRow['birthday'] === $birthday && $existingRow['username'] === $username);
	if ($restart || $tripleMatch || $nameBirthMatch) {
		$_SESSION['restart'] = true;
		$ori_password = mysqli_real_escape_string($con, (string) $existingRow['password']);
		$result = $con->query( "UPDATE `users` SET `password`='" . aes128_enc($password) . "', `ori_password`='" . aes128_enc($ori_password) . "', `password_edit` = '".date('Y-m-d H:i:s')."' WHERE `userid`='" . $userid . "' AND `birthday`='" . $birthday . "' AND `username`='" . $username . "'");
	} else {
		echo json_encode(['result' => 'fail', 'error' => '회원정보오류입니다 고객센터에 문의해주세요']);
		//mysqli_close($con);
		exit;
	}
} else {
	if ($restart) {
		echo json_encode(['result' => 'fail', 'error' => '회원 정보를 찾을 수 없습니다.']);
		//mysqli_close($con);
		exit;
	}
	$sql = "INSERT INTO `users` (`userid`,`password`,`telecom`,`birthday`,`gender`,`username`,`isMvno`,`reg_dt`,`account_number`,`account_name`,`bank`,`is_first`) VALUES ('" . $userid . "','" . aes128_enc($password) . "','" . $telecom . "','" . $birthday . "','" . $gender . "','" . $username . "','" . $isMvno . "','" . $reg_dt . "','" . aes128_enc($account) . "','" . $username . "','" . $bank . "','1')";
	$result = $con->query( $sql);
}
if (!$result) {
	echo json_encode(['result' => 'fail', 'error' => '다시 시도해주세요.']);
	//mysqli_close($con);
	exit;
}
if (!empty($data['credential'])) {
	try {
		$credentialData = $data['credential'];

		// Android 앱 또는 iOS 앱에서 온 credential인지 확인
		$isAndroidBiometric = false;
		if (isset($credentialData['response']['clientDataJSON'])) {
			$clientDataJSON = base64_decode($credentialData['response']['clientDataJSON']);
			$clientData = json_decode($clientDataJSON, true);
			if ((isset($clientData['android_biometric']) && $clientData['android_biometric'] === true) ||
				(isset($clientData['ios_biometric']) && $clientData['ios_biometric'] === true)) {
				$isAndroidBiometric = true;
			}
		}

		if ($isAndroidBiometric) {
			// Android 앱에서 온 경우 - 간단한 처리
			file_put_contents(__DIR__ . '/debug.log', "Android biometric credential detected\n", FILE_APPEND);
			$credential_id = $credentialData['id'];
			$public_key = 'android_biometric_key_' . $userid;  // Android는 실제 public key를 생성하지 않음
		} else {
			// 일반 WebAuthn 처리
			$attestationStatementSupportManager = new \Webauthn\AttestationStatement\AttestationStatementSupportManager();
			$attestationStatementSupportManager->add(new \Webauthn\AttestationStatement\NoneAttestationStatementSupport());
			$attestationObjectLoader = new \Webauthn\AttestationStatement\AttestationObjectLoader($attestationStatementSupportManager);
			$credentialLoader = new \Webauthn\PublicKeyCredentialLoader($attestationObjectLoader);
			$credential = $credentialLoader->loadArray($credentialData);
			$attestationObject = $credential->getResponse()->getAttestationObject();
			if (method_exists($attestationObject, 'getAuthData')) {
				$authenticatorData = $attestationObject->getAuthData();
			} elseif (method_exists($attestationObject, 'getRawAuthData')) {
				$authenticatorData = $attestationObject->getRawAuthData();
			} else {
				throw new Exception('AttestationObject에 getAuthData()/getRawAuthData() 메서드가 없습니다.');
			}
			$attestedCredData = $authenticatorData->getAttestedCredentialData();
			if (!$attestedCredData) {
				throw new Exception('No attested credential data found');
			}
			$credential_id = base64_encode($attestedCredData->getCredentialId());
			$public_key = base64_encode($attestedCredData->getCredentialPublicKey());
		}
		$credential_id_esc = mysqli_real_escape_string($con, $credential_id);
		$public_key_esc = mysqli_real_escape_string($con, $public_key);
		$credChk = $con->query( "SELECT 1 FROM `credentials` WHERE `userid`='" . $userid . "' LIMIT 1");
		if ($credChk && mysqli_num_rows($credChk) > 0) {
			$con->query( "UPDATE `credentials` SET `credential_id`='" . $credential_id_esc . "', `public_key`='" . aes128_enc($public_key_esc) . "' WHERE `userid`='" . $userid . "'");
		} else {
			$con->query( "INSERT INTO `credentials` (`userid`,`credential_id`,`public_key`) VALUES ('" . $userid . "','" . $credential_id_esc . "','" . aes128_enc($public_key_esc) . "')");
		}
		$_SESSION['userid'] = $userid;
		$_SESSION['username'] = $username;
		$_SESSION['password'] = $password;
		echo json_encode(['result' => 'success']);
	} catch (Exception $e) {
		echo json_encode(['result' => 'fail', 'error' => 'WebAuthn 등록 오류: ' . $e->getMessage()]);
	}
} else {
	$_SESSION['userid'] = $userid;
	$_SESSION['username'] = $username;
	$_SESSION['password'] = $password;
	echo json_encode(['result' => 'success']);
}
//mysqli_close($con);
?>