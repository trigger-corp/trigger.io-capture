/* global forge */

forge["capture"] = {
    /**
     * Allow the user to select an image and give a file object representing it.
     *
     * @param {Object} props
     * @param {function({uri: string, name: string})=} success
     * @param {function({message: string}=} error
     */
    "getImage": function (props, success, error) {
        if (typeof props === "function") {
            error = success;
            success = props;
            props = {};
        }
        if (!props) {
            props = {};
        }
        forge.internal.call("capture.getImage", props, success && function (file) {
            success(file);
        }, error);
    },

    /**
     * Allow the user to select a video and give a file object representing it.
     *
     * @param {Object} props
     * @param {function({uri: string, name: string})=} success
     * @param {function({message: string}=} error
     */
    "getVideo": function (props, success, error) {
        if (typeof props === "function") {
            error = success;
            success = props;
            props = {};
        }
        if (!props) {
            props = {};
        }
        forge.internal.call("capture.getVideo", props, success && function (file) {
            success(file);
        }, error);
    }
};
