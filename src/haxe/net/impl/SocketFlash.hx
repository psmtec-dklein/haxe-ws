package haxe.net.impl;

import flash.net.SecureSocket;
import haxe.io.Bytes;
import flash.utils.ByteArray;
import flash.events.ProgressEvent;
import flash.events.IOErrorEvent;
import flash.events.Event;
import flash.utils.Endian;
import flash.net.Socket;

class SocketFlash extends Socket2 {
    private var impl: Socket;

	// TODO (DK) debug stuff only, remove when testing is finished
	private static var cnt = 0;
	private var id = cnt++;
	// /TODO (DK) debug stuff only, remove when testing is finished
	
    public function new(host:String, port:Int, secure:Bool, debug:Bool = false) {
        super(host, port, debug);

        this.impl = secure ? new SecureSocket() : new Socket();
        this.impl.endian = Endian.BIG_ENDIAN;
        this.impl.addEventListener(flash.events.Event.CONNECT, connectHandler);
        this.impl.addEventListener(flash.events.Event.CLOSE, closeHandler);
        this.impl.addEventListener(flash.events.IOErrorEvent.IO_ERROR, ioErrorHandler, false, 0, true);
        this.impl.addEventListener(flash.events.ProgressEvent.SOCKET_DATA, socketDataHandler);
        this.impl.connect(host, port);
    }

	function connectHandler(e:Event) {
		if (debug) trace('${id} SocketFlash.connect');
		this.onconnect();
	}
	
	function closeHandler(e:Event) {
		if (debug) trace('${id} SocketFlash.close');
		this.onclose();
	}

	// TODO (DK) automatically call close or let the user do it?
	function ioErrorHandler(e:IOErrorEvent) {
		if (debug) trace('${id} SocketFlash.io_error');
		this.onerror();
	}

	function socketDataHandler(e:ProgressEvent) {
		var out = new ByteArray();
		impl.readBytes(out, 0, impl.bytesAvailable);
		out.position = 0;
		if (debug) trace('${id} SocketFlash.socket_data:' + out.toString());
		this.ondata(Bytes.ofData(out));
	}
	
    override public function close() {
        impl.removeEventListener(flash.events.Event.CONNECT, connectHandler);
        impl.removeEventListener(flash.events.Event.CLOSE, closeHandler);
        impl.removeEventListener(flash.events.IOErrorEvent.IO_ERROR, ioErrorHandler);
        impl.removeEventListener(flash.events.ProgressEvent.SOCKET_DATA, socketDataHandler);
        impl.close();
		impl = null;
    }

    override public function send(data:Bytes) {
        var ba:ByteArray = data.getData();
        if (debug) {
            trace('${id} SocketFlash.send($ba) : ${ba.position} : ${ba.length}');
        }
        impl.writeBytes(ba);
        impl.flush();
    }
}
