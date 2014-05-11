<?php

function init($libraries=array()){
	$root_folder = '/cygdrive/z';
	$files = array();
	scan_folders($root_folder, $files);
	foreach ($files as $dir => $srt) {
		echo "Modifying $srt\n";
		$content = file_get_contents($srt);
		$content = strip_tags($content);
		/*$content = preg_replace('/Created and Encoded by(.*)/', '-', $content);
		$content = preg_replace('/Subtitles re-synced by(.*)/', '-', $content);
		$content = preg_replace('/Subtitles downloaded from(.*)/', '-', $content);
		$content = preg_replace('/Best watched using(.*)/', '-', $content);
		$content = preg_replace('/>>(.*)/', '-', $content);*/
		file_put_contents($srt . '', $content);
		//file_put_contents($srt . '.1', $content);
		//unlink ($srt . '.1');
	}	
	
}

function scan_folders($directory, &$results, $file_ext='srt'){
	$files = glob($directory . '/*', GLOB_NOSORT);
	if(is_array($files) && count($files) > 0){
		foreach ($files as $name) {
			if(is_dir($name)) {
				scan_folders($name, $results);
			}
			elseif(is_file($name)){
				$path_info = pathinfo($name);
				if($path_info['extension'] == $file_ext) {
					$results[strtolower($path_info['filename'])] = $name;
				}
			}
		}
	}
}

init();

?>