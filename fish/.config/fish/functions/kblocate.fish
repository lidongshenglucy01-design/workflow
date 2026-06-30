function kblocate
    set note_file "$HOME/lala/linux_tools.md"
    set cmd $argv[1]

    switch "$cmd"
        case add
            # 用法: kblocate add "标题" "内容"
            if test (count $argv) -lt 3
                echo "用法: kblocate add <标题> <内容>"
            else
                printf "\n## %s\n%s\n" $argv[2] $argv[3] >>$note_file
                echo "已记录: $argv[2]"
            end

        case ''
            # 这里的 --preview 逻辑改用单引号保护整体，内部变量用双引号展开
            grep -n "^## " $note_file | fzf --prompt="知识库 > " \
                --height=80% \
                --layout=reverse \
                --with-nth=2.. \
                --preview 'sed -n "$(echo {1} | cut -d: -f1),\$p" '$note_file' | sed -n "1d; /^##/q; p" | glow -s dark' \
                --bind "enter:execute(kitty @ launch --type=overlay nvim +$(echo {1} | cut -d: -f1) '$note_file')"
        case '*'
            echo "用法: kblocate [add|查找]"
    end
end
