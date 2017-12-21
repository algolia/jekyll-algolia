const { runMode } = require('codemirror/addon/runmode/runmode.node');
require('codemirror/mode/css/css');
require('codemirror/mode/htmlmixed/htmlmixed');
require('codemirror/mode/jsx/jsx');
require('codemirror/mode/toml/toml');
require('codemirror/mode/ruby/ruby');
require('codemirror/mode/shell/shell');
require('codemirror/mode/yaml/yaml');
const escape = require('escape-html');

module.exports = function highlight(source, languageCode) {
  let tokenizedSource = '';

  const languageMapping = {
    html: 'htmlmixed',
    javascript: 'jsx',
    json: 'jsx',
    js: 'jsx',
    ruby: 'ruby',
    shell: 'shell',
    toml: 'toml',
    yaml: 'yaml',
    yml: 'yaml',
  };
  const languageParser = languageMapping[languageCode];

  const codeType = languageParser === 'shell' ? 'Command' : 'Code';

  // this is a synchronous callback API
  runMode(source, languageParser, (text, style) => {
    const escapedText = escape(text);

    if (!style) {
      tokenizedSource += escapedText;
      return;
    }

    tokenizedSource += `<span class="cm-${style.replace(/ +/g, ' cm-')}">${
      escapedText
    }</span>`;
  });

  return `<pre class="code-sample cm-s-mdn-like codeMirror ${
    languageParser
  }" data-code-type="${codeType}"><div class="code-wrap"><code>${
    tokenizedSource
  }</code></div></pre>`;
};
