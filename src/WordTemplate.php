<?php

namespace archfz\Word;

/**
 * Class WordTemplate.
 *
 * Provides means to generate word documents from templates.
 */
class WordTemplate {

  /**
   * Stores the template documents full path.
   *
   * @var string
   */
  protected $templatePath;

  /**
   * Stores the jobs/actions to generate the desired document.
   *
   * @var array
   */
  protected $jobs = [];

  /**
   * WordTemplate constructor.
   *
   * @param string $templatePath
   *    Full path to the template word document.
   */
  public function __construct($templatePath) {
    $this->templatePath = $templatePath;
  }

  /**
   * Pastes bookmarked object.
   *
   * @param string $bookmark
   *    The name of the bookmark.
   *
   * @return WordTemplate
   *    Self.
   */
  public function paste($bookmark) {
    $this->jobs[] = ['values' => [], 'paste' => $bookmark];
    return $this;
  }

  /**
   * Sets value of a placeholder.
   *
   * @param string $placeholder
   *    Name of the placeholder. Without the container brackets: {}.
   * @param mixed $value
   *    Value to set in place of the placeholder.
   *
   * @return WordTemplate
   *    Self.
   */
  public function setValue($placeholder, $value) {
    // Placeholders are case in-sensitive.
    $placeholder = strtolower($placeholder);

    // Get last job definition.
    end($this->jobs);
    $currentJob = &$this->jobs[key($this->jobs)];

    if (empty($currentJob)) {
      throw new \LogicException('Cannot set value, as there is nothing yet. Use ::paste first.');
    }

    $currentJob['values'][$placeholder] = $value;

    return $this;
  }

  /**
   * Compiles the document and saves it.
   *
   * @param string $destination
   *    Optional output directory.
   * @param string $filename
   *    Optional output filename.
   *
   * @throws \Exception
   *    When running the command fails.
   */
  public function compile($destination = NULL, $filename = NULL) {
    $cwd = getcwd();
    $command = './owgen';

    if (empty($destination)) {
      $destination = $cwd;
    }

    $command .= ' -d "' . $destination . '"';

    if ($filename) {
      $command .= ' -f "' . $filename . '"';
    }

    $templatePath = $this->templatePath;
    // Add current working directory to the template path if it is not an
    // absolute path.
    if ($templatePath[0] !== DIRECTORY_SEPARATOR && preg_match('~\A[A-Z]:(?![^/\\\\])~i', $templatePath) === 0) {
      $templatePath = $cwd . DIRECTORY_SEPARATOR . $templatePath;
    }

    $command .= ' "' . $templatePath . '"';

    $descriptorspec = array(
      0 => array("pipe", "r"),  // stdin
      1 => array("pipe", "w"),  // stdout
      2 => array("pipe", "a"),  // stderr
    );

    chdir(dirname(__FILE__) . '/../native/');
    $process = proc_open($command, $descriptorspec, $pipes);

    $stdout = '';
    $stderr = '';

    if(($error = stream_get_contents($pipes[2])) != false) {
      throw new \Exception('Error in command: ' . $error);
    } else {
      stream_set_blocking($pipes[2], 1);

      fwrite($pipes[0], json_encode($this->jobs));
      fclose($pipes[0]);

      /* Prepare the read array */
      $read   = array($pipes[1], $pipes[2]);
      $write  = NULL;
      $except = NULL;
      $tv_sec = 1;      // secs
      $tv_usec = 1000;  // millionths of secs

      if(false === ($rv = stream_select($read, $write, $except, $tv_sec, $tv_usec))) {
        throw new \Exception('error in stream_select');
      } else if ($rv > 0) {
        foreach($read as $pipe_resource) {
          if($pipe_resource == $pipes[1]) {
            $stdout .= stream_get_contents($pipes[1]);
          } else if($pipe_resource == $pipes[2]) {
            $stderr .= stream_get_contents($pipes[1]);
          }
        }
      } else {
        // select timed out. plenty of stuff can be done here
      }
    }

    // Set back initial current directory.
    chdir($cwd);
    $status = proc_get_status($process);

    if ($status['exitcode'] !== 0) {
      throw new \Exception('Failed to compile template: ' . $stdout . $stderr);
    }
  }

}
