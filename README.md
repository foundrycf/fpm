fpm
===
a package manager for [foundry](http://github.com/joshuairl/foundry)

This is not even an alpha... purely in it's concept stages.
Thinking of using Foundry as a way to do a port of NPM to CF.

One of our goals with Foundry is to make porting Node-based apps a cinch.

##Usage Examples
###From the CLI
Install all defined dependencies in foundry.json (in your project)<br />
`fpm install`<br />
<br />
Install a single module (in your project)<br />
`fpm install UnderscoreCF`<br />
<br />
Install a single module globally (for all projects to use).<br />
`fpm install UnderscoreCF -g`<br />
<br />
Create a foundry symlink to a project folder globally (for all projects to use). <br />
This is handy for installing your own stuff, so that you can work on it and test it iteratively without having to continually rebuild.<br />
`fpm link`

###From the url
Install all defined dependencies in foundry.json (in your project)<br />
`http://my-project/foundry/cli.cfc?method=install`<br />
<br />
Install a single module (in your project)<br />
`http://my-project/foundry/cli.cfc?method=install&id=UnderscoreCF`<br />
<br />
Install a single module globally (for all projects to use).<br />
`http://my-project/foundry/cli.cfc?method=install&id=UnderscoreCF&opts=g`<br />
<br />
Create a foundry symlink to a project folder globally (for all projects to use). <br />
This is handy for installing your own stuff, so that you can work on it and test it iteratively without having to continually rebuild.<br />
`http://my-project/foundry/cli.cfc?method=link`