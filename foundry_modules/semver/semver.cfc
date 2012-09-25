component name="semver" {
  public semver function init() {
    variables.RegExp = require("RegExp");
    variables._ = require("UnderscoreCF");

    // See http://semver.org/
    // This implementation is a *hair* less strict in that it allows
    // v1.2.3 things, and also tags that don't begin with a char.

    var semver = "\\s*[v=]*\\s*([0-9]+)"  // major
                & "\\.([0-9]+)"           // minor
                & "\\.([0-9]+)"           // patch
                & "(-[0-9]+-?)?"          // build
                & "([a-zA-Z-][a-zA-Z0-9-\.:]*)?"; // tag
    var exprComparator = "^((<|>)?=?)\s*("&semver&")$|^$";
    var xRangePlain = "[v=]*([0-9]+|x|X|\\*)"
                    & "(?:\\.([0-9]+|x|X|\\*)"
                    & "(?:\\.([0-9]+|x|X|\\*)"
                    & "([a-zA-Z-][a-zA-Z0-9-\.:]*)?)?)?";
    var xRange = "((?:<|>)=?)?\\s*" & xRangePlain;
    var exprSpermy = "(?:~>?)"&xRange;

    this.expressions =
        { parse : new RegExp("^\\s*"&semver&"\\s*$")
        , parsePackage : new RegExp("^\\s*([^\/]+)[-@](" &semver&")\\s*$")
        , parseRange : new RegExp(
            "^\\s*(" + semver + ")\\s+-\\s+(" & semver & ")\\s*$")
        , validComparator : new RegExp("^"&exprComparator&"$")
        , parseXRange : new RegExp("^"&xRange&"$")
        , parseSpermy : new RegExp("^"&exprSpermy&"$")
        }


    _.forEach(structKeyList(this.expressions),function (i) {
      this[i] = function (str) {
        return expressions[i].match("" & (str || ""));
      }
    });

    this.rangeReplace = ">=$1 <=$7"
    this.clean = clean
    this.compare = compare
    this.rcompare = rcompare
    this.satisfies = satisfies
    this.gt = gt
    this.gte = gte
    this.lt = lt
    this.lte = lte
    this.eq = eq
    this.neq = neq
    this.cmp = cmp
    this.inc = inc

    this.valid = valid
    this.validPackage = validPackage
    this.validRange = validRange
    this.maxSatisfying = maxSatisfying

    this.replaceStars = replaceStars
    this.toComparators = toComparators

    // range can be one of:
    // "1.0.3 - 2.0.0" range, inclusive, like ">=1.0.3 <=2.0.0"
    // ">1.0.2" like 1.0.3 - 9999.9999.9999
    // ">=1.0.2" like 1.0.2 - 9999.9999.9999
    // "<2.0.0" like 0.0.0 - 1.9999.9999
    // ">1.0.2 <2.0.0" like 1.0.3 - 1.9999.9999
    variables.starExpression = "(<|>)?=?\s*\*";
    variables.starReplace = "";
    variables.compTrimExpression = new RegExp("((<|>)?=?)\\s*("
                                        &semver&"|"&xRangePlain&")", "g");
    variables.compTrimReplace = "$1$3";
  }

  public any function stringify (version) {
    var v = version
    return [v[1]||'', v[2]||'', v[3]||''].join(".") + (v[4]||'') + (v[5]||'');
  }

  public any function clean (version) {
    version = this.parse(version)
    if (!version) return version
    return stringify(version)
  }

  public any function valid (version) {
    if (typeof version NEQ "string") return null
    return this.parse(version) && version.trim().replace(/^[v=]+/, '')
  }

  public any function validPackage (version) {
    if (typeof version NEQ "string") return null
    return version.match(expressions.parsePackage) && version.trim()
  }

  function toComparators (range) {
    var ret = trim((range || ""))
    ret = replace(expressions.parseRange, this.rangeReplace)
    ret = replace(compTrimExpression, compTrimReplace)
    ret = _.split(ret,/\s+/)
    ret = _.join(ret," ")
    ret = _.split(ret,"||")
    ret = _.map(ret,function (orchunk) {
              orchunk = _.split(orchunk," ");
              orchunk = _.map(orchunk,replaceXRanges);
              orchunk = _.map(orchunk,replaceSpermies);
              orchunk = _.map(orchunk,replaceStars);
              orchunk = _.join(orchunk," ");
              orchunk = trim(orchunk);

        return orchunk;
      });
    ret = _.map(ret,function (orchunk) {
        orchunk = trim(orchunk);
        orchunk = _.split(orchunk,"\s+");
        orchunk = _.filter(orchunk,function (c) { return c.match(expressions.validComparator); });
        return orchunk;
      })
    ret = _.filter(ret,function (c) { return c.length; });
    return ret;
  }

  function replaceStars (stars) {
    stars = trim(stars);
    stars = replace(starExpression,starReplace);

    return stars;
  }

  // "2.x","2.x.x" --> ">=2.0.0- <2.1.0-"
  // "2.3.x" --> ">=2.3.0- <2.4.0-"
  function replaceXRanges (ranges) {
    ranges = _.split(ranges,"\s+");
    ranges = _.map(ranges,replaceXRange);
    ranges = _.join(ranges," ");
    return ranges;
  }

  function replaceXRange (version) {
    version = trim(version);
    version = replace(version,expressions.parseXRange,function(v,gtlt,M,m,p,t) {
      var anyX = (!M || LCase(M) EQ "x" || M EQ "*"
                   || !m || LCase(m) EQ "x" || m EQ "*"
                   || !p || LCase(p) EQ "x" || p EQ "*");
      var ret = v;

        if (gtlt && anyX) {
          // just replace x-es with zeroes
          (!M || M EQ "*" || LCase(M) EQ "x") && (M = 0);
          (!m || m EQ "*" || LCase(m) EQ "x") && (m = 0);
          (!p || p EQ "*" || LCase(p) EQ "x") && (p = 0);
          ret = gtlt & M&"."&m&"."&p&"-";
        } else if (!M || M EQ "*" || LCase(M) EQ "x") {
          ret = "*"; // allow any
        } else if (!m || m EQ "*" || LCase(m) EQ "x") {
          // append "-" onto the version, otherwise
          // "1.x.x" matches "2.0.0beta", since the tag
          // *lowers* the version value
          ret = ">="&M&".0.0- <"&(&M&1)&".0.0-";
        } else if (!p || p EQ "*" || LCase(p) EQ "x") {
          ret = ">="&M&"."&m&".0- <"&M&"."&(&m&1)&".0-";
        }
        //console.error("parseXRange", [].slice.call(arguments), ret)
        return ret;
      });
      
      return version;
  }

  // ~, ~> --> * (any, kinda silly)
  // ~2, ~2.x, ~2.x.x, ~>2, ~>2.x ~>2.x.x --> >=2.0.0 <3.0.0
  // ~2.0, ~2.0.x, ~>2.0, ~>2.0.x --> >=2.0.0 <2.1.0
  // ~1.2, ~1.2.x, ~>1.2, ~>1.2.x --> >=1.2.0 <1.3.0
  // ~1.2.3, ~>1.2.3 --> >=1.2.3 <1.3.0
  // ~1.2.0, ~>1.2.0 --> >=1.2.0 <1.3.0
  function replaceSpermies (version) {
    version = trim(version);
    version = replace(version,expressions.parseSpermy,
                                  function (v, gtlt, M, m, p, t) {
      if (gtlt) throw (
        "Using '"&gtlt&"' with ~ makes no sense. Don't do it.");

      if (!M || LCase(M) EQ "x") {
        return "";
      }
      // ~1 == >=1.0.0- <2.0.0-
      if (!m || LCase(m) EQ "x") {
        return ">="&M&".0.0- <"&(&M&1)&".0.0-";
      }
      // ~1.2 == >=1.2.0- <1.3.0-
      if (!p || LCase(p) EQ "x") {
        return ">="&M&"."&m&".0- <"&M&"."&(&m&1)&".0-";
      }
      // ~1.2.3 == >=1.2.3- <1.3.0-
      t = t || "-"
      return ">="&M&"."&m&"."&p&t&" <"&M&"."&(&m&1)&".0-";
      });
      
      return version;
  }

  function validRange (range) {
    range = replaceStars(range);
    var c = toComparators(range);
    return (len(c) EQ 0)
         ? null
         : _.join(_.map(c,function (c) { return _.join(c," ") }),"||")
  }

  // returns the highest satisfying version in the list, or undefined
  function maxSatisfying (versions, range) {
    versions = _.filter(versions,function(v) { return satisfies(v,range) });
    versions = _.sort(compare);
    versions = new foundry.array(versions);

    return versions.pop();
  }

  function satisfies (version, range) {
    version = valid(version);
    if (!version) return false;
    range = toComparators(range);
    for (var i = 0, l = range.length ; i < l ; i ++) {
      var ok = false;
      for (var j = 0, ll = range[i].length ; j < ll ; j ++) {
        var r = range[i][j];
        var gtlt = left(r,1) EQ ">" ? gt : left(r,1) EQ "<" ? lt : false;
        var eq = r.charAt(!!gtlt) EQ "=";
        var sub = (!!eq) + (!!gtlt);

        if (!gtlt) eq = true;

        r = r.substr(sub);
        r = (r EQ "") ? r : valid(r);
        ok = (r EQ "") || (eq && r EQ version) || (gtlt && gtlt(version, r));
        if (!ok) break;
      }
      if (ok) return true;
    }
    return false;
  }

  // return v1 > v2 ? 1 : -1
  function compare (v1, v2) {
    var g = gt(v1, v2)
    return ((g EQ null) ? 0 : g) ? 1 : -1
  }

  function rcompare (v1, v2) {
    return compare(v2, v1)
  }

  function lt (v1, v2) { return gt(v2, v1) }
  function gte (v1, v2) { return !lt(v1, v2) }
  function lte (v1, v2) { return !gt(v1, v2) }
  function eq (v1, v2) { return (gt(v1, v2) EQ null) }
  function neq (v1, v2) { return (gt(v1, v2) NEQ null) }
  function cmp (v1, c, v2) {
    switch (c) {
      case ">": return gt(v1, v2);
      case "<": return lt(v1, v2);
      case ">=": return gte(v1, v2);
      case "<=": return lte(v1, v2);
      case "==": return eq(v1, v2);
      case "!=": return neq(v1, v2);
      case "EQ": return (v1 EQ v2);
      case "NEQ": return (v1 NEQ v2);
      default: throw ("Y U NO USE VALID COMPARATOR!? "&c);
    };
  }

  // return v1 > v2
  function num (v) {
    return (isDefined(v) ? 0 : reReplace(v||"0","[^0-9]+",""), 10);
  }

  function gt (v1, v2) {
    v1 = this.parse(v1);
    v2 = this.parse(v2);
    if (!v1 || !v2) return false;

    for (var i = 1; i < 5; i ++) {
      v1[i] = num(v1[i]);
      v2[i] = num(v2[i]);
      if (v1[i] > v2[i]) return true
      else if (v1[i] NEQ v2[i]) return false;
    }
    // no tag is > than any tag, or use lexicographical order.
    var tag1 = v1[5] || "";
    var tag2 = v2[5] || "";

    // kludge: null means they were equal.  falsey, and detectable.
    // embarrassingly overclever, though, I know.
    return (((tag1 EQ tag2) ? null
                   : !tag1) ? true
               : !tag2) ? false
           : tag1 > tag2
  }

  function inc (version, release) {
    version = this.parse(version);
    if (!version) return null;

    var parsedIndexLookup = { 
        'major': 1
      , 'minor': 2
      , 'patch': 3
      , 'build': 4 
    }
    var incIndex = parsedIndexLookup[release];
    if (!isDefined(incIndex)) return null;

    var current = num(version[incIndex])
    version[incIndex] = (current EQ -1) ? 1 : current + 1;

    for (var i = incIndex + 1; i < 5; i ++) {
      if (num(version[i]) NEQ -1) version[i] = "0";
    }

    if (version[4]) version[4] = "-" + version[4];
    version[5] = "";

    return stringify(version);
  }
}










})(typeof exports EQ "object" ? exports : semver = {})
