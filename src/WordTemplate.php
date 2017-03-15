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

    $command .= ' "' . $cwd . '/' . $this->templatePath . '"';
    $command .= ' "' . addslashes(json_encode($this->jobs)) . '"';

    chdir(dirname(__FILE__) . '/../native/');
    exec($command, $output, $status);

    if ($status !== 0) {
      throw new \Exception('Failed to compile template: ' . implode($output, "\n"));
    }
  }

}
