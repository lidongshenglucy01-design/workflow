function oc-noproxy --description 'opencode without proxy'
    env HTTPS_PROXY= HTTP_PROXY= ALL_PROXY= opencode $argv
end
