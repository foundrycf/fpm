component extends="foundry.core" {
	public any function init() {
		var path = require("path");
		var templates = {};

		return function(name, context, sync) {
		  var emitter = new foundry.core.emitter();

		  var templateName = name & '.mustache';
		  var templatePath = path.join(path.dirname(getComponentMetaData(this).path), '../../templates/', templateName);

		  if (structKeyExists(arguments,'sync')) {
		    if (!templates[templatePath]) templates[templatePath] = fs.readFileSync(templatePath, 'utf-8');
		    return hogan.compile(templates[templatePath]).renderWithColors(context);
		  } else if (templates[templatePath]) {
		    emitter.emit('data', hogan.compile(templates[templatePath]).renderWithColors(context));
		  } else {
		    fs.readFile(templatePath, 'utf-8', function (err, file) {
		      templates[templatePath] = file;
		      emitter.emit('data', hogan.compile(file).renderWithColors(context));
		    });
		  }

		  return emitter;
		};;
	}
}