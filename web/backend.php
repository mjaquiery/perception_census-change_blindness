<?php
/*
PHP file to make database info available to html/javascript requests in XML format

Expected incoming data:
	Trial Type (3-digit flag set)
	Success/Failure (binary)
	Response Time (int)
	UID (string - session ID, hashed?)
	Browser (string)
	Lab Conditions (binary)

Incoming data is NOT TRUSTED

XML File Format:
<?xml version="1.0" encoding="ISO-8859-1"?>

<RESULTS>
	<MEAN>1.35</MEAN>
</RESULTS>
<ERROR>
	<TEXT></TEXT>
</ERROR>
*/

// Function definitions


// Class definitions


// Variable definitions
// incoming variables
$trialType; // flags
$trialSuccess = false;
$trialTime = 0;
$trialUID = "";
$trialBrowser = "";
$trialLab = false;
$requestResponse = false;

// PHP variables
$db; // mysqli object
$query; // mysqli query object
$tableName = "";
$rt;
$rt_total = 0;
$trials = 1;

// XML variables
$errorText = "";
$mean = 0.0;

// Sanitize incoming data
$trialType = int($_GET["tt"]); // flags
$trialSuccess = ($_GET["s"]==1 ? true : false);
$trialTime = int($_GET["t"]);
$trialUID = cleanString($_GET["UID"]);
$trialBrowser = cleanString($_GET["browser"]);
$trialLab = ($_GET["lab"]==1 ? true : false);
$requestResponse = ($_GET["rr"]==1 ? true : false);

// Update database
$db = new mysqli("host", "username", "password");
/*
 * This is the "official" OO way to do it,
 * BUT $connect_error was broken until PHP 5.2.9 and 5.3.0.
 */
if($db->connect_error) {
	// connection error
	$errorText = "Sorry, there was a problem connecting to the database, the trial result has not been recorded.";
}
else {
	if($query = $db->prepare("INSERT INTO $tableName VALUES (?, ? ,? ,? ,?, ?)")) {
		$query->bind_param("iiissi", $trialType, $trialSuccess, $trialTime, $trialUID, $trialBrowser, $trialLab);
		$query->execute();
		$query->close();

		if($requestResponse) {
			// Query database
			if($query = $db->prepare("SELECT responseTime FROM $tableName WHERE trialType=? AND UID=?")) {
				$query->bind_param("is", $trialType, $trialUID);
				$query->execute();
				$query->bind_result($rt);
				while($query->fetch()) {
					$rt_total += $rt;
				}
				$trials = $db->affected_rows;
				$query->close();

				// Prepare XML vars
				if($trials == 0)
					$mean = 0.0;
				else {
					$mean = $rt_total/$trials;
				}
			}
			else {
				$errorText = "Sorry, there was a problem retrieving results from the database.";
			}
		}
	}
	else {
		$errorText = "Sorry, there was a problem inserting your results into the database.";
	}
	// close the database connection
	$db->close();
}
// Provide response data
echo "
	<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>

	<RESULTS>
		<MEAN>$mean</MEAN>
	</RESULTS>
	<ERROR>
		<TEXT>$errorText</TEXT>
	</ERROR>
";

?>
