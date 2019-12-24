<html>
<head><title>Test Results</title></head>
<body>
<a href="thumbnails/">Thumbnails</a><hr/>
<?php

$results = [];
$types   = [];

$format_names = ["multi", "pdf", "png", "svgz"];

$time_files = glob("test*.time");
sort($time_files);
foreach ($time_files as $test) {
    preg_match('|test-(\w+)-(\w+)-(\w+).time|', $test, $m);

    $type   = $m[1];
    $style  = $m[2];
    $format = $m[3];

    if (!isset($results[$type])) $results[$type] = array();
    if (!isset($results[$type][$style])) $results[$type][$style] = array();

    $results[$type][$style][$format] = basename($test, ".time");

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
      if ($format === "multi") $format="pdf";
      echo "<td ";
      if(file_exists("$base.$format")) {
        echo "bgcolor='lightgreen' align='right'>";
        echo "&nbsp;<a href='$base.$format'>";
        readfile("$base.time");
        echo "</a>&nbsp;";
      } else {
        echo "bgcolor='orangered' align='center'>";
        echo "<a href='$base.err'>FAIL</a>";
      }
      echo "</td>";
    }

    echo "</tr>\n";
  }

  echo "</table>\n";
}
?>

</body>
</html>

