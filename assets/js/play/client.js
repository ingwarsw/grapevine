import React from 'react';
import {Provider} from 'react-redux';

import Keys from './keys';
import {store} from "./redux/store";

import ConnectionStatus from "./components/connection_status";
import Gauges from "./components/gauges";
import Prompt from "./components/prompt";
import SocketProvider from "./components/socket_provider";
import Terminal from "./components/terminal";

let body = document.getElementById("body");
let userToken = body.getAttribute("data-user-token");
let sessionToken = body.getAttribute("data-session-token");

const keys = new Keys();

document.addEventListener('keydown', e => {
  if (!keys.isModifierKeyPressed()) {
    document.getElementById('prompt').focus();
  }
});

class Client extends React.Component {
  render() {
    return (
      <Provider store={store}>
        <SocketProvider game={this.props.game} userToken={userToken} sessionToken={sessionToken}>
          <div className="play">
            <div className="alert alert-warning">
              <b>NOTE:</b> This web client is in <b>beta</b>.
            </div>

            <ConnectionStatus />

            <div className="window">
              <Terminal />
              <Gauges gauges={this.props.gauges} />
              <Prompt />
            </div>
          </div>
        </SocketProvider>
      </Provider>
    );
  }
}

export {Client}
