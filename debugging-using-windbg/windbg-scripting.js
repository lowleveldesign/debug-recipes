"use strict";

/*
.scriptunload windbg-scripting.js;
.scriptload c:\temp\windbg-scripting.js
*/

function initializeScript()
{
    return [new host.apiVersionSupport(1, 7), new host.functionAlias(runTest, "runTest")]
}

function runTest() {
    function dumpKeys(o, indent) {
        for (const prop of Object.keys(o)) {
            if (typeof o[prop] === 'function') {
                host.diagnostics.debugLog(`${indent}function ${prop}\n`)
            } else {
                host.diagnostics.debugLog(`${indent}field    ${prop} : ${typeof o[prop]}\n`)
                dumpKeys(o[prop], indent + '  ')
            }
        }
    }

    //dumpKeys(host, '');
    logn(`sizeof(int) : ${host.evaluateExpression('sizeof(int)').asNumber()}`)
}

function log(s) {
    host.diagnostics.debugLog(s)
}

function logn(s) {
    log(s + "\n")
}
