<?php 

function init($libraries=array()){
    $root_folder = '/cygdrive/z';
    foreach (glob($root_folder . '/*') as $foldername) {
        echo "$foldername\n";
		if ($foldername == 'done-dir') {
			continue;
		}
        foreach (glob($foldername . '/*') as $filename) {
            if (is_dir($filename)) {
                deltree($filename);
            } elseif (preg_match('/\.jpg$|\.txt$|\.nfo$/i', $filename)) {
                unlink($filename);
            } else {
                $original_file_name = explode('/', $filename);
                $original_file_name = end($original_file_name);

                $path_info = pathinfo($original_file_name);
                $extension = $path_info['extension'];
                
                $original_folder_name = explode('/', $foldername);
                $original_folder_name = end($original_folder_name);
                
                $new_file_name = str_replace($original_file_name, $original_folder_name . '.' . $extension, $filename);
                
				echo ("renaming $filename to $new_file_name\n");
                rename($filename, $new_file_name);
                
            }
        
        }   
    }

}

function deltree($dir) {
    $files = array_diff(scandir($dir), array('.','..'));
    foreach ($files as $file) {
        (is_dir("$dir/$file")) ? deltree("$dir/$file") : unlink("$dir/$file");
    }
    return rmdir($dir);
}


init();

?>