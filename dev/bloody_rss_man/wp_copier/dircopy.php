<?php

	function smart_delete($dirname) {
		if (is_dir($dirname))
			$dir_handle = opendir($dirname);
		if (!$dir_handle)
			return false;
		while($file = readdir($dir_handle)) {
			if ($file != "." && $file != "..") {
			if (!is_dir($dirname."/".$file))
				unlink($dirname."/".$file);
			else
				smart_delete($dirname.'/'.$file);    
			}
		}
		closedir($dir_handle);
		rmdir($dirname);
		return true;
	}

   function smartCopy($source, $dest, $folderPermission=0755,$filePermission=0644){ 
# source=file & dest=dir => copy file from source-dir to dest-dir 
# source=file & dest=file / not there yet => copy file from source-dir to dest and overwrite a file there, if present 

# source=dir & dest=dir => copy all content from source to dir 
# source=dir & dest not there yet => copy all content from source to a, yet to be created, dest-dir 
    $result=false; 
    
    if (is_file($source)) { # $source is file 
        if(is_dir($dest)) { # $dest is folder 
            if ($dest[strlen($dest)-1]!='/') # add '/' if necessary 
                $__dest=$dest."/"; 
            $__dest .= basename($source); 
            } 
        else { # $dest is (new) filename 
            $__dest=$dest; 
            } 
        $result=copy($source, $__dest); 
        chmod($__dest,$filePermission); 
        } 
    elseif(is_dir($source)) { # $source is dir 
        if(!is_dir($dest)) { # dest-dir not there yet, create it 
            @mkdir($dest,$folderPermission); 
            chmod($dest,$folderPermission); 
            } 
        if ($source[strlen($source)-1]!='/') # add '/' if necessary 
            $source=$source."/"; 
        if ($dest[strlen($dest)-1]!='/') # add '/' if necessary 
            $dest=$dest."/"; 

        # find all elements in $source 
        $result = true; # in case this dir is empty it would otherwise return false 
        $dirHandle=opendir($source); 
        while($file=readdir($dirHandle)) { # note that $file can also be a folder 
            if($file!="." && $file!="..") { # filter starting elements and pass the rest to this function again 
#                echo "$source$file ||| $dest$file<br />\n"; 
                $result=smartCopy($source.$file, $dest.$file, $folderPermission, $filePermission); 
                } 
            } 
        closedir($dirHandle); 
        } 
    else { 
        $result=false; 
        } 
    return $result; 
    } 

function loadfile($file) {
	$handle = fopen($file, "r");
	$contents = fread($handle, filesize($file));
	fclose($handle);
	return $contents;
}

function filerecord($file, $contents) {
  $handle = fopen($file, "w");
  fwrite ($handle, $contents);
  fclose($handle);
}

$db_name=$HTTP_POST_VARS['db_name'];
$dir_name=$HTTP_POST_VARS['dir_name'];

if ($db_name && $dir_name) {
	# copy wordpress
  if (is_dir("../$dir_name")) {
    if (smartCopy("../1wp","../$dir_name")) {
      $path = "../$dir_name/wp-config.php";
      $file = loadfile($path);
      $file = str_replace("define('DB_NAME', 'db_name')","define('DB_NAME', '$db_name')",$file);
      filerecord($path,$file);
      $message = "Directory copied successfully";
      
      # select a theme to be copied

			# get all themes
			$themes_base = "../1themes";
			$theme_dir = opendir($themes_base);
			$has_themes = false;
			while($file = readdir($theme_dir)){
				if ($file!='.' && $file!='..' && is_dir("$themes_base/$file")){
					$list[] = $file;
					$has_themes = true;
				}
			}
			closedir($theme_dir);
			if($has_themes){
				shuffle($list);
				$theme = $list[0];
				# move the theme to the target folder
				if(smartCopy("$themes_base/$theme", "../$dir_name/wp-content/themes/$theme")){
					if(!smart_delete("$themes_base/$theme"))
						$message = "$message Warning: Cannot delete theme $theme.";
				} else {
					$message = "$message Warning: theme $theme was not copied.";
				}
					
					
			} else {
				$message = "$message Warning: no theme!";
			}

    }
  } else {
    $message = "No such directory";
  }
} else {
  $message = "Select the directory and database";
}
?>

<html>
<body>
<form action="dircopy.php" method="post"> 
Directory: <input type="text" name="dir_name" value="<?php echo $dir_name?>"><br>
Database: <input type="text" name="db_name" value="<?php echo $db_name?>"><br>
<input type="submit" value="Copy dir"><br><br>
<?php echo $message; ?>
</form>
</body>
</html>