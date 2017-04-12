<html>
<head><title>Test Results</title></head>
<body>
<?php

$results = [];
$types   = [];

foreach (glob("test*.png") as $test) {
    preg_match('|test-(\w+)-(\w+)-(\w+).png|', $test, $m);

    $type   = $m[1];
    $style  = $m[2];
    $format = $m[3];

    if (!isset($results[$type])) $results[$type] = array();
    if (!isset($results[$type][$style])) $results[$type][$style] = array();

    $results[$type][$style][$format] = basename($test, ".png");

    $types[$type] = $type;
}

foreach ($types as $type) {
  echo "<h1>$type</h1>\n";

  echo "<table>\n";

  echo "<tr><th>$type</th>";
  foreach($format_names as $format) {
    echo "<th>$format</th>";
  }
  echo "</tr>\n";

  foreach($results[$type] as $style => $formats) {
    echo "<tr><td>$style</td>";

    foreach($formats as $format => $base) {
      echo "<td>";
      echo "<a href='../$base.png'><img src='$base.png'/></a>";
      echo "</td>";
    }

    echo "</tr>\n";
  }

  echo "</table>\n";
}
?>

</body>
</html>