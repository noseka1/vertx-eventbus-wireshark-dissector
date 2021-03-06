----------------------------------------
-- script-name: vertx_eventbus_dissector.lua
--
-- author: Ales Nosek <ales.nosek@gmail.com>
-- Copyright (c) 2019, Ales Nosek
-- This code is in the Public Domain, or the BSD (3 clause) license if Public Domain does not apply
-- in your country.
--
-- To create this script I used the dissector.lua example Lua script by Hadriel Kaplan found at:
-- https://wiki.wireshark.org/Lua/Examples
--
-- OVERVIEW:
-- This script creates an elementary dissector for the Vert.x EventBus protocol. This is the protocol used
-- by Vert.x nodes that communicate over EventBus in clustered mode.
--
-- HOW TO RUN THIS SCRIPT:
-- Wireshark and Tshark support multiple ways of loading Lua scripts: through a dofile() call in init.lua,
-- through the file being in either the global or personal plugins directories, or via the command line.
-- See the Wireshark User's Guide chapter on Lua (https://wiki.wireshark.org/Lua). This sample command-line
-- worked for me:
--
-- $ wireshark -X lua_script:vertx_eventbus_dissector.lua
--
-- Once the script is loaded, it creates a new protocol named "Vert.x EventBus Protocol" (or "VERTX_EVENTBUS"
-- in some places).  If you have a capture file with Vert.x EventBus packets in it, simply select one in the
-- Packet List pane, right-click on it, and select "Decode As ...", In the dialog box that shows up, click the
-- + button to add a decoding rule. Click the (none) in the last column of the decoding rule. Scroll down the
-- list of protocols to one called "VERTX_EVENTBUS", select that and click the "ok" or "apply" button.
-- Voila`, you're now decoding Vert.x EventBus packets using the simplistic dissector in this script.
--
----------------------------------------
local debug_level = 1

function dprint(...)
    if debug_level > 0 then
        print(table.concat({"Lua:", ...}," "))
    end
end

dprint("Wireshark version = ", get_version())
dprint("Lua version = ", _VERSION)

local vertx_eventbus = Proto("vertx_eventbus", "Vert.x EventBus Protocol")

local codec_names = {
    [-1] = "usercodec",
    [0]  = "null",
    [1]  = "ping",
    [2]  = "byte",
    [3]  = "boolean",
    [4]  = "short",
    [5]  = "int",
    [6]  = "long",
    [7]  = "float",
    [8]  = "double",
    [9]  = "string",
    [10] = "char",
    [11] = "buffer",
    [12] = "bytearray",
    [13] = "jsonobject",
    [14] = "jsonarray",
    [15] = "replyexception"
}

-- types of reply failure
local failure_types = {
    [0] = "TIMEOUT",
    [1] = "NO_HANDLERS",
    [2] = "RECIPIENT_FAILURE"
}

-- pong
local pf_pong                  = ProtoField.new("Pong", "vertx_eventbus.pong", ftypes.INT8)
-- message fields
local pf_message_length        = ProtoField.new("Message length", "vertx_eventbus.message_length", ftypes.INT32)
local pf_wire_protocol_version = ProtoField.new("Wire protocol version", "vertx_eventbus.wire_protocol_version", ftypes.INT8)
local pf_codec_id              = ProtoField.new("Codec ID", "vertx_eventbus.codec_id", ftypes.INT8, codec_names)
local pf_codec_name            = ProtoField.new("Codec name", "vertx_eventbus.codec_name", ftypes.STRING)
local pf_send                  = ProtoField.new("Send", "vertx_eventbus.send", ftypes.INT8, { [0] = "send", [1] = "publish" })
local pf_address               = ProtoField.new("Address", "vertx_eventbus.address", ftypes.STRING)
local pf_reply_address         = ProtoField.new("Reply address", "vertx_eventbus.reply_address", ftypes.STRING)
local pf_sender_port           = ProtoField.new("Sender port", "vertx_eventbus.sender_port", ftypes.INT32)
local pf_sender_host           = ProtoField.new("Sender host", "vertx_eventbus.sender_host", ftypes.STRING)
-- message headers
local pf_headers               = ProtoField.new("Headers", "vertx_eventbus.headers", ftypes.NONE)
local pf_header                = ProtoField.new("Header", "vertx_eventbus.header", ftypes.NONE)
local pf_header_key            = ProtoField.new("Key", "vertx_eventbus.header_key", ftypes.STRING)
local pf_header_value          = ProtoField.new("Value", "vertx_eventbus.header_value", ftypes.STRING)
--- message body
local pf_body_byte             = ProtoField.new("Body", "vertx_eventbus.body", ftypes.INT8)
local pf_body_boolean          = ProtoField.new("Body", "vertx_eventbus.body", ftypes.INT8, { [0] = "true", [1] = "false" })
local pf_body_int16            = ProtoField.new("Body", "vertx_eventbus.body", ftypes.INT16)
local pf_body_int32            = ProtoField.new("Body", "vertx_eventbus.body", ftypes.INT32)
local pf_body_int64            = ProtoField.new("Body", "vertx_eventbus.body", ftypes.INT64)
local pf_body_float            = ProtoField.new("Body", "vertx_eventbus.body", ftypes.FLOAT)
local pf_body_double           = ProtoField.new("Body", "vertx_eventbus.body", ftypes.DOUBLE)
local pf_body_string           = ProtoField.new("Body", "vertx_eventbus.body", ftypes.STRING)
local pf_body_bytes            = ProtoField.new("Body", "vertx_eventbus.body", ftypes.BYTES)
--- reply failure body
local pf_failure_type          = ProtoField.new("Failure type", "vertx_eventbus.failure_type", ftypes.INT8, failure_types)
local pf_failure_code          = ProtoField.new("Failure code", "vertx_eventbus.failure_code", ftypes.INT32)
local pf_failure_includes_msg  = ProtoField.new("Failure includes message", "vertx_eventbus.failure_includes_message", ftypes.INT8, { [0] = "no message", [1] = "message included" })
local pf_failure_message       = ProtoField.new("Failure message", "vertx_eventbus.failure_message", ftypes.STRING)

vertx_eventbus.fields = {
    pf_pong,
    pf_message_length,
    pf_wire_protocol_version,
    pf_codec_id,
    pf_codec_name,
    pf_send,
    pf_address,
    pf_reply_address,
    pf_sender_port,
    pf_sender_host,
    pf_headers,
    pf_header,
    pf_header_key,
    pf_header_value,
    pf_body_byte,
    pf_body_boolean,
    pf_body_int16,
    pf_body_int32,
    pf_body_int64,
    pf_body_float,
    pf_body_double,
    pf_body_string,
    pf_body_bytes,
    pf_failure_type,
    pf_failure_code,
    pf_failure_includes_msg,
    pf_failure_message
}

local message_length_field = Field.new("vertx_eventbus.message_length")
local message_codec_id = Field.new("vertx_eventbus.codec_id")
local message_failure_includes_msg = Field.new("vertx_eventbus.failure_includes_message")

-- expert info
local ef_reply_exception = ProtoExpert.new("vertx_eventbus.response.expert", "Vert.x EventBus Reply Exception", expert.group.RESPONSE_CODE, expert.severity.CHAT)

vertx_eventbus.experts = {
    ef_reply_exception
}

function read_fixed_length(tvbuf, pos, tree, len, item_type)
    tree:add(item_type, tvbuf:range(pos, len))
    return pos + len
end

function read_var_length(tvbuf, pos, tree, item_type)
    local len = tvbuf:range(pos, 4):int()
    if len > 0 then
        tree:add(item_type, tvbuf:range(pos + 4, len))
    end
    return pos + 4 + len
end

function read_var_length_json(tvbuf, pos, tree, item_type, pktinfo)
    local len = tvbuf:range(pos, 4):int()
    if len > 0 then
        item = tree:add(item_type, tvbuf:range(pos + 4, len))
        status, json_dissector = pcall(function () return Dissector.get("json") end)
        if status then
            json_dissector:call(tvbuf:range(pos + 4, len):tvb(), pktinfo, item)
        else
            dprint("Failed to obtain json dissector:", tostring(json_dissector))
        end
    end
    return pos + 4 + len
end

function body_read_null(tvbuf, pos, tree)
    return pos
end

function body_read_ping(tvbuf, pos, tree)
    return pos
end

function body_read_byte(tvbuf, pos, tree)
    return read_fixed_length(tvbuf, pos, tree, 1, pf_body_byte)
end

function body_read_boolean(tvbuf, pos, tree)
    return read_fixed_length(tvbuf, pos, tree, 1, pf_body_boolean)
end

function body_read_short(tvbuf, pos, tree)
    return read_fixed_length(tvbuf, pos, tree, 2, pf_body_int16)
end

function body_read_int(tvbuf, pos, tree)
    return read_fixed_length(tvbuf, pos, tree, 4, pf_body_int32)
end

function body_read_long(tvbuf, pos, tree)
    return read_fixed_length(tvbuf, pos, tree, 8, pf_body_int64)
end

function body_read_float(tvbuf, pos, tree)
    return read_fixed_length(tvbuf, pos, tree, 4, pf_body_float)
end

function body_read_double(tvbuf, pos, tree)
    return read_fixed_length(tvbuf, pos, tree, 8, pf_body_double)
end

function body_read_string(tvbuf, pos, tree)
    return read_var_length(tvbuf, pos, tree, pf_body_string)
end

function body_read_char(tvbuf, pos, tree)
    return read_fixed_length(tvbuf, pos, tree, 2, pf_body_int16)
end

function body_read_buffer(tvbuf, pos, tree)
    return read_var_length(tvbuf, pos, tree, pf_body_bytes)
end

function body_read_byte_array(tvbuf, pos, tree)
    return read_var_length(tvbuf, pos, tree, pf_body_bytes)
end

function body_read_json_object(tvbuf, pos, tree, pktinfo)
    return read_var_length_json(tvbuf, pos, tree, pf_body_string, pktinfo)
end

function body_read_json_array(tvbuf, pos, tree, pktinfo)
    return read_var_length_json(tvbuf, pos, tree, pf_body_string, pktinfo)
end

function body_read_reply_exception(tvbuf, pos, tree)
    tree:add_proto_expert_info(ef_reply_exception, "Reply exception")
    pos = read_fixed_length(tvbuf, pos, tree, 1, pf_failure_type)
    pos = read_fixed_length(tvbuf, pos, tree, 4, pf_failure_code)
    pos = read_fixed_length(tvbuf, pos, tree, 1, pf_failure_includes_msg)
    if message_failure_includes_msg()() == 1 then
       pos = read_var_length(tvbuf, pos, tree, pf_failure_message)
    end
    return pos
end

local body_decoders = {
    [0]  = body_read_null,
    [1]  = body_read_ping,
    [2]  = body_read_byte,
    [3]  = body_read_boolean,
    [4]  = body_read_short,
    [5]  = body_read_int,
    [6]  = body_read_long,
    [7]  = body_read_float,
    [8]  = body_read_double,
    [9]  = body_read_string,
    [10] = body_read_char,
    [11] = body_read_buffer,
    [12] = body_read_byte_array,
    [13] = body_read_json_object,
    [14] = body_read_json_array,
    [15] = body_read_reply_exception
}

function decode_headers(tvbuf, pos, tree)
    local len = tvbuf:range(pos, 4):int()
    if len > 4 then
        headers = tree:add(pf_headers)
        local pos2 = pos + 4
        local i = tvbuf:range(pos2, 4):int()
        pos2 = pos2 + 4
        while i > 0 do
            header = headers:add(pf_header)
            pos2 = read_var_length(tvbuf, pos2, header, pf_header_key)
            pos2 = read_var_length(tvbuf, pos2, header, pf_header_value)
            i = i - 1
        end
    end
    return pos + len
end

function vertx_eventbus.dissector(tvbuf,pktinfo,root)
    dprint("vertx_eventbus.dissector called")

    -- set the protocol column to show our protocol name
    pktinfo.cols.protocol:set("Vert.x EventBus")

    local pktlen = tvbuf:reported_length_remaining()

    -- add our protocol to the dissection display tree
    local tree = root:add(vertx_eventbus, tvbuf:range(0,pktlen))

    local pos = 0

    -- handle pong
    if pktlen == 1 then
        if tvbuf:range(pos, 1):int() == 1 then
            pos = read_fixed_length(tvbuf, pos, tree, 1, pf_pong)
        end
        return pos
    end

    -- handle event bus message
    pos = read_fixed_length(tvbuf, pos, tree, 4, pf_message_length)
    pos = read_fixed_length(tvbuf, pos, tree, 1, pf_wire_protocol_version)
    pos = read_fixed_length(tvbuf, pos, tree, 1, pf_codec_id)
    local codec_id = message_codec_id()()
    if codec_id == -1 then
        pos = read_var_length(tvbuf, pos, tree, pf_codec_name)
    end
    pos = read_fixed_length(tvbuf, pos, tree, 1, pf_send)
    pos = read_var_length(tvbuf, pos, tree, pf_address)
    pos = read_var_length(tvbuf, pos, tree, pf_reply_address)
    pos = read_fixed_length(tvbuf, pos, tree, 4, pf_sender_port)
    pos = read_var_length(tvbuf, pos, tree, pf_sender_host)

    pos = decode_headers(tvbuf, pos, tree)

    if codec_id >= 0 and codec_id <= 15 then
        if codec_id == 13 or codec_id == 14 then
            pos = body_decoders[codec_id](tvbuf, pos, tree, pktinfo)
        else
            pos = body_decoders[codec_id](tvbuf, pos, tree)
        end
    else
        tree:add(pf_body_bytes, tvbuf:range(pos, pktlen - pos))
        pos = pktlen
    end

    dprint("vertx_eventbus.dissector returning",pos)

    -- tell wireshark how much of tvbuff we dissected
    return pos
end

-- There's no specific TCP protocol the Vert.x EventBus uses.
-- Add our dissector to Wireshark's "Decode As..." list
DissectorTable.get("tcp.port"):add_for_decode_as(vertx_eventbus)
