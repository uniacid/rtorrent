#!/usr/bin/python
# irc relay
# -*- encoding: utf-8 -*-

from twisted.words.protocols import irc
from twisted.internet import protocol
from twisted.internet import reactor
from twisted.internet import endpoints
import xml.dom.minidom as minidom
import uuid, os, sys, subprocess, os.path, atexit
from string import Template
import re
os.remove("relay.pid")
pfile="relay.pid"
fpid = os.fork()
if fpid!=0:
  f = open(pfile, 'w')
  f.write(str(fpid))
  f.close()
  sys.exit(0)
  sys.argv[0] = 'irc-relay'


class RelayBot(irc.IRCClient):
    @property
    def encoding(self):
        return self.factory.encoding

    @property
    def nickname(self):
        return self.factory.nickname.encode(self.encoding)

    @property
    def identd(self):
        return self.factory.identd.encode(self.encoding)

    @property
    def realname(self):
        return self.factory.realname.encode(self.encoding)

    def signedOn(self):
        for channel in self.factory.channels:
            channel_encoded = channel.encode(self.encoding)
            self.join(channel_encoded)

    def privmsg(self, user, channel, msg):
        self.on_msg('PRIVMSG', user, channel, msg)

    def pubmsg(self, user, channel, msg):
        self.on_msg('PUBMSG', user, channel, msg)

    def action(self, user, channel, msg):
        self.on_msg('ACTION', user, channel, msg)

    def kickedFrom(self, channel, kicker, message):
        self.join(channel)

    def on_msg(self, msgtype, user, channel, msg):
        server_u = self.factory.server_name
        channel_u = channel.decode(self.encoding, 'ignore')
        user_u = user.decode(self.encoding, 'ignore')
        msg_u = msg.decode(self.encoding, 'ignore')

        self.factory.event_notify.on_msg(msgtype,
                                         server_u, channel_u, user_u, msg_u)

class RelayBotFactory(protocol.ReconnectingClientFactory):
    protocol = RelayBot

    def __init__(self, config, event_notify):
        self.server_name = config['name']
        self.channels = config['channels']
        self.nickname = config['nickname']
        self.identd = config['identd']
        self.realname = config['realname']
        self.encoding = config['encoding']
        self.event_notify = event_notify

    def buildProtocol(self, addr):
        proto = protocol.ReconnectingClientFactory.buildProtocol(self, addr)
        self.connectedProtocol = proto
        return proto


class RelayServer:
    def __init__(self, config_file_path):
        self.parse_config(config_file_path)
        self.factories = {}
        for server in self.config['servers']:
            factory = RelayBotFactory(server, self)
            reactor.connectTCP(server['hostname'], server['port'], factory)
            self.factories[server['name']] = factory

    def parse_config(self, config_file_path):
        dom_doc = minidom.parse(config_file_path)
        dom_root = dom_doc.firstChild

        assert(dom_doc.hasChildNodes() and len(dom_doc.childNodes) == 1)
        assert(dom_root.localName == u'config')

        config = {}
        config['servers'] = []
        config['relaygroups'] = []
        
        for dom_server in dom_root.getElementsByTagName('server'):
            data = {}
            data['name'] = dom_server.getAttribute('name')
            data['hostname'] = dom_server.getAttribute('hostname')
            data['port'] = int(dom_server.getAttribute('port'))
            data['nickname'] = dom_server.getAttribute('nickname')
            data['identd'] = dom_server.getAttribute('identd')
            data['realname'] = dom_server.getAttribute('realname')
            data['encoding'] = dom_server.getAttribute('encoding')
            data['channels'] = []
            for dom_channel in dom_server.getElementsByTagName('channel'):
                name = dom_channel.getAttribute('channel')
                data['channels'].append(name)
            config['servers'].append(data)

        for dom_rg in dom_root.getElementsByTagName('relaygroup'):
            data = {}
            data['name'] = dom_rg.getAttribute('name')
            data['outputformat'] = dom_rg.getAttribute('outputformat')
            pattern = dom_rg.getAttribute('ignore')
            if pattern:
                data['ignore'] = re.compile(pattern)
            maxmessagebytes = dom_rg.getAttribute('maxmessagebytes')
            if maxmessagebytes:
                data['maxmessagebytes'] = int(maxmessagebytes)
            data['nodes'] = []
            for dom_node in dom_rg.getElementsByTagName('node'):
                k = {}
                k['server'] = dom_node.getAttribute('server')
                k['channel'] = dom_node.getAttribute('channel')
                input = (dom_node.getAttribute('input') == 'true')
                k['input'] = input
                output = (dom_node.getAttribute('output') == 'true')
                k['output'] = output
                fmtstr = dom_node.getAttribute('outputformat')
                if fmtstr:
                    k['outputformat'] = fmtstr
                pattern = dom_node.getAttribute('ignore')
                if pattern:
                    k['ignore'] = pattern
                maxmessagebytes = dom_node.getAttribute('maxmessagebytes')
                if maxmessagebytes:
                    k['maxmessagebytes'] = int(maxmessagebytes)
                data['nodes'].append(k)
            config['relaygroups'].append(data)

        self.config = config

    def run(self):
        reactor.run()

    def get_input_relay_groups(self, server, channel):
        def has_input_relay_channel(group):
            for node in  group['nodes']:
                if (node['server'] == server and
                    node['channel'] == channel and
                    node['input']):
                    return True
            return False
        return filter(has_input_relay_channel, self.config['relaygroups'])

    def on_msg(self, msgtype, server, channel, user, msg):
        def get_output_nodes(group):
            def is_output_node(node):
                return node['output']
            return filter(is_output_node, group['nodes'])

        def truncate_irc_msg(text, encoding, max_bytes):

            line = text.encode(encoding,'replace')[:max_bytes].decode(encoding, 'ignore')
                
            if len(line) == len(text):
                return line
            else:
                if not line[-1].isspace() and not text[len(line)].isspace():

                    m = re.compile(u'^(.*\s)[^\s]+$').match(line)
                    if m:
                        line = m.group(1)
                return line

        def format_line(fmtstr, server, channel, user, msg):
            nickname, userhost = user.split('!', 1)
            template = Template(fmtstr)
            f = template.substitute(nickname=nickname,
                                    servername=server,
                                    channel=channel, message=msg)
            return f

        def format_lines(fmtstr, server, channel, user, msg, encoding,
                         max_bytes):

            prefix_len = len(format_line(fmtstr, server, channel, user, ''))
            max_bytes -= prefix_len
            lines = []

            while (len(msg) > 0):
                m = truncate_irc_msg(msg, encoding, max_bytes)
                if not m:
                    break
                f = format_line(fmtstr, server, channel, user, m)
                lines.append(f)
                msg = msg[len(m):]

            return lines

        def send_relay(fmtstr, server, channel, user, msg, max_bytes,
                       msgtype, proto, ochannel):
            if not max_bytes:
                msgf = format_line(fmtstr, server, channel, user, msg)
                encoded = msgf.encode(proto.encoding)
                if msgtype == 'PRIVMSG':
                    proto.say(ochannel, encoded)
                elif msgtype == 'ACTION':
                    proto.describe(ochannel, encoded)
                return

            lines = format_lines(fmtstr, server, channel, user, msg,
                                 proto.encoding, max_bytes)
            for line in lines:
                encoded = line.encode(proto.encoding, 'ignore')

                if msgtype == 'PRIVMSG':
                    proto.say(ochannel.encode(proto.encoding), encoded)
                elif msgtype == 'ACTION':
                    proto.describe(ochannel.encode(proto.encoding), encoded)


        if msgtype != 'PRIVMSG' and msgtype != 'ACTION':
            return

        for relaygroup in self.get_input_relay_groups(server, channel):
            try:
                match = relaygroup['ignore'].match(msg)
                if relaygroup['ignore'].match(msg):
                    continue
            except KeyError:
                pass

            for node in get_output_nodes(relaygroup):
                if node['server'] == server and node['channel'] == channel:
                    continue
                try:
                    if node['ignore'].match(msg):
                        continue
                except KeyError:
                    pass
                oserver = node['server']
                ochannel = node['channel']
                factory = self.factories[oserver]
                try:
                    proto = factory.connectedProtocol
                except AttributeError:
                    continue
                if node.has_key('outputformat'):
                    output_format = node['outputformat']
                else:
                    output_format = relaygroup['outputformat']
                if node.has_key('maxmessagebytes'):
                    max_bytes = node['maxmessagebytes']
                else:
                    max_bytes = relaygroup['maxmessagebytes']

                send_relay(output_format, server, channel, user, msg, max_bytes,
                           msgtype, proto, ochannel)

    def on_pubmsg(self, server, channel, user, msg):
        print u'PUBMSG %s@%s/%s: %s' % (user, server, channel, msg)
        
    def on_action(self, server, channel, user, msg):
        print u'ACTION %s@%s/%s: %s' % (user, server, channel, msg)


if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        config_file = sys.argv[1]
    else:
        config_file = "settings.xml"
    s = RelayServer(config_file)
    s.run()
    os.unlink(pfile)
