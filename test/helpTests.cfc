component name="testHelp" extends="mxunit.framework.testcase" {
	public void function setUp() {
		variables.fpm = new lib.index();
    variables.emitter = new foundry.core.emitter();
    variables._ = new foundry.core.util();
    variables.console = new foundry.core.console();
	}

  public void function Should_have_line_method() {
    assert(_.isFunction(fpm.line.help));
  };

  public void function Should_return_an_emiter() {
    assertEquals(fpm.help(), emitter);
  };

  public void function Should_emit_end_event() {
    var testData = "";
    var help = fpm.help('info');
    
    help.on('end',function(data) {
      testData = data;
    });

    assert(!_.isEmpty(data));
  };

  public void function Should_emit_end_event_with_data_string(next) {
    help('install').on('end', function (data) {
      assert(isString(data));
      next();
    });
  };
}