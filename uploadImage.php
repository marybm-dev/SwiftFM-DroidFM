<?php
  $target_dir = "ImageUploads";

  // make sure this directory exits, create it if it doesn't
  if (!file_exists($target_dir)) {
    mkdir($target_dir, 0777, true);
  }

  $target_dir = $target_dir . "/" . basename($_FILES["file"]["name"]);

  if (move_uploaded_file($_FILES["file"]["tmp_name"], $target_dir)) {
    echo json_enconde ([
      "message" => "The file " . basename($_FILES["file"]["name"]). " has been uploaded.",
      "path" => $target_dir
    ]);
  }
  else {
    echo json_enconde ([
      "message" => "Error: " . basename($_FILES["file"]["error"]),
      "path" => $target_dir
    ]);
  }
?>
