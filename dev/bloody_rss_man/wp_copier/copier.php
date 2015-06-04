<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="content-type" content="text/html; charset=iso-8859-1" />
  <title>Wordpress copier</title>
</head>
<body>
	<h3>Welcome to copier</h3>

<?php
	
	$rm = getenv('REQUEST_METHOD');
	
	$input_dest = 'destname';
	$input_database = 'dbname';
	
	$base_dir = '~/public_html';
	$wp_base = $base_dir . '/1wp';
	$themes_base = $base_dir . '/1themes';
	
	$wp_config = $wp_base . '/wp-config.php';
	
	if ($rm=='POST'){
		$dest = $_REQUEST[$input_dest];
		$db = $_REQUEST[$input_database];

		$ok = false;
		
		if($db){
			
			if(file_exists($wp_config)){
				
				# read configuration
				$config = read_file($wp_config);
				
				# change database name
				$pattern = "/define\('DB_NAME',\s*'.*?'\);/";
				$replacement = "define('DB_NAME', '$db');";
				write_file($wp_config, preg_replace($pattern, $replacement, $config));
				echo "<i>Database name was changed to $db</i><br/>";
				
				# copy wordpress
				
				$wp_source = $wp_base . '/*';
				$wp_dest = "$base_dir/$dest";
				
				# check existence of the destination folder
				if(file_exists($wp_dest) && is_dir($wp_dest)){

					# do copy wordpress
					if(do_exec("cp -r $wp_source $wp_dest")){
						echo "<i>Wordpress was copied to $wp_dest</i><br/>";
						# copied, let's copy a theme
						
						# get all themes
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
							echo "<i>Using theme $theme</i><br/>";
							
							if(do_exec("cp $themes_base/$theme $wp_dest/wp-content/themes")){
								
								
								
								$ok = true;
							}
						} else {
							echo "<b>No themes</b><br/>";
						}
						
					}
				} else {
					echo "<b>No target directory $wp_dest</b><br/>";
				}
			} else {
				echo "<b>No file $wp_config</b><br/>";
			}
		} else {
			echo "<b>Please specify the database name</b><br/>";
		}
		
		if ($ok)
			echo "Your request was successfully processed.<br/>";
		
		echo "<br/><br/><a href=".">Back to copier</a>";
		
	} else {
		echo "<form name='data' method='post'>";

			echo "Enter name ot the destination directory under the '/public_html':<br/>";
			echo "<input type='text' name='$input_dest' /><br/><br/>";
		
			echo "Enter database name:<br/>";
			echo "<input type='text' name='$input_database' /><br/><br/>";
			
			echo "<input type='submit' value=' Ok ' />";
		
		echo "</form>";
	}

function do_exec($cmd) {
	$code;
	$output;
	exec($cmd, &$output, &$code);
	if($code!=0){
		echo "<b>Cannot execute $cmd:</b><br/><pre>";
		echo implode("<br/>", $output);
		echo "</pre><br/>";
		return false;
	} else
		return true;
}

function write_file($filename, $newdata) {
	$f = fopen($filename, "w");
	fwrite($f, $newdata);
	fclose($f);  
}

function read_file($filename) {
	$f = fopen($filename, "r");
	$data=fread($f, filesize($filename));
	fclose($f);  
	return $data;
}

?>

</body>
</html>
