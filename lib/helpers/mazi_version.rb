VERSION = '1.6.1'

module MaziVersion
  def getVersion
    VERSION
  end

  def fetch
    `git fetch`
  end

  def current_version?
    fetch
    status = `git status`
    status.split("\n").each do |line|
      if line.start_with? "Your branch"
        return true if line.include? "up-to-date"
        return false
      end
    end
  end

  def version_difference
    fetch
    status = `git status`
    status.split("\n").each do |line|
      if line.start_with? "Your branch"
        return 0 if line.include? "up-to-date"
        return line.split[-2]
      end
    end
  end

  def staged?
    fetch
    status = `git status`
    status.split("\n").each do |line|
      return true  if line.start_with? "Changes not staged for commit:"
    end
    false
  end

  # On branch master
  #   Your branch is ahead of 'origin/master' by 11 commits.
  #     (use "git push" to publish your local commits)
  #   nothing to commit, working directory clean
  # On branch master
  #   Your branch is up-to-date with 'origin/master'.
  #   Changes not staged for commit:
  #     (use "git add <file>..." to update what will be committed)
  #     (use "git checkout -- <file>..." to discard changes in working directory)

  #     modified:   README.md
  #     modified:   lib/helpers/mazi_version.rb
  #   no changes added to commit (use "git add" and/or "git commit -a")
  # On branch master
  #   Your branch is up-to-date with 'origin/master'.
  #   nothing to commit, working directory clean
  def version_update
    fetch
    diff   = version_difference
    staged = staged?
    puts "#{diff} - #{staged}"
    if diff > 0 && !staged
      `git pull`
      `cd /root/back-end && git pull`
    end
    nil
  end
end

# class TestVersion
#   include MaziVersion
# end

# o = TestVersion.new

# puts o.getVersion

# puts o.current_version?

# puts o.version_difference

# puts o.version_update