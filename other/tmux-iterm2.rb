require 'formula'

class TmuxIterm2 < Formula
  url 'http://iterm2.googlecode.com/files/tmux-for-iTerm2-20120203.tar.gz'
  md5 '59305a26bdd0245054fe719e6b2a960e'
  homepage 'http://github.com/gnachman/tmux2'

  depends_on 'libevent'

  def install
    ENV.append "LDFLAGS", '-lresolv'
    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}", "--sysconfdir=#{etc}"
    system "make install"

    # Install bash completion scripts for use with bash-completion
    (prefix+'etc/bash_completion.d').install "examples/bash_completion_tmux.sh" => 'tmux-iterm2'
  end

  def caveats; <<-EOS.undent
    Bash completion script was installed to:
      #{etc}/bash_completion.d/tmux-iterm2
    EOS
  end
end
