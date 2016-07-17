var ZHBridge = window.ZHBridge || {};
window.ZHBridge = ZHBridge;

ZHBridge.Core = ZHBridge.Core || (function () {
  var callbackId = 1;
  var callbacks = {};
  var actionQueue = [];

  var createBridge = function () {
    var iFrame;
    iFrame = document.createElement("iframe");
    iFrame.setAttribute("src", "ZHBridge://__BRIDGE_LOADED__");
    iFrame.setAttribute("style", "display:none;");
    iFrame.setAttribute("height", "0px");
    iFrame.setAttribute("width", "0px");
    iFrame.setAttribute("frameborder", "0");
    document.body.appendChild(iFrame);
    setTimeout(function () {
      document.body.removeChild(iFrame)
    }, 0);
  };

  var callNativeHandler = function () {
    var actionName = arguments[0];
    var actionArgs = arguments[1] || [];
    var successCallback = arguments[2];
    var failCallback = arguments[3];
    var actionId = ++callbackId;

    if (successCallback || failCallback) {
      callbacks[actionId] =  {success:successCallback, fail:failCallback};
    } else {
      actionId = 0;
    }

    var action = {
      id: actionId,
      name: actionName,
      args: actionArgs,
      argsCount: actionArgs.length
    };
    if (window.webkit && window.webkit.messageHandlers
      && window.webkit.messageHandlers.ZHBridge
      && window.webkit.messageHandlers.ZHBridge.postMessage) {
      window.webkit.messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))
    } else if (window.zhbridge_messageHandlers
      && window.zhbridge_messageHandlers.ZHBridge
      && window.zhbridge_messageHandlers.ZHBridge.postMessage) {
      window.zhbridge_messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))
    } else {
      actionQueue.push(action);
      createBridge();
    }
  };
  var getAndClearQueuedActions = function () {
    var json = JSON.stringify(actionQueue);
    actionQueue = [];
    return json;
  };
  var callbackJs = function () {
    var data = arguments[0];
    if (!data){
      return
    }
    var callInfo = JSON.parse(data);
    var callbackId = callInfo["id"];
    var status = callInfo["status"];
    var args = callInfo["args"];
    if (!callbackId || status == undefined || args == undefined) {
      return
    }
    var callback = callbacks[callbackId];
    var success = callback["success"];
    var fail = callback["fail"];
    if (!callback) {
      return
    }
    var result = undefined;
    if (status && success) {
      result = success.apply(this, args);
    } else if (!status && fail) {
      result = fail.apply(this, args);
    }
    return result != undefined ? JSON.stringify(result) : undefined;
  };

  var handlerMapper = {};
  var callJsHandler = function (data) {
    var callInfo = JSON.parse(data);
    var name = callInfo["name"];
    var args = callInfo["args"];
    var argsCount = callInfo["argsCount"];
    if (!name || argsCount == undefined || argsCount != args.length) {
      return;
    }

    var handler = handlerMapper[name];
    if (handler) {
      var result = handler.apply(this, args);
      return result != undefined ? JSON.stringify(result) : undefined
    }
  };
  var registerJsHandler = function (handlerName, callback) {
    handlerMapper[handlerName] = callback
  };

  var ready =  function () {
    var readyFunction = arguments[0];
    if (readyFunction) {
      document.addEventListener("DOMContentLoaded", readyFunction);
    }
  };

  return {
    // for native side
    getAndClearJsActions: getAndClearQueuedActions,
    callJsHandler: callJsHandler,
    callbackJs: callbackJs,

    // for js
    registerJsHandler: registerJsHandler,
    callNativeHandler: callNativeHandler,

    ready: ready
  }
}());