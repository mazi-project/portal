VERSION = '1.6.1'

module MaziVersion
  def getVersion
    VERSION
  end

  def current?
    `git fetch`
    status = `git status`
    status.split("\n").each do |line|
      if line.start_with? "Your branch"
        return true if line.include? "up-to-date"
        return false
      end
    end
  end

  def difference
    `git fetch`
    status = `git status`
    status.split("\n").each do |line|
      if line.start_with? "Your branch"
        return 0 if line.include? "up-to-date"
        return line.split[-2]
      end
    end
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
  def update

  end
end

class TestVersion
  include MaziVersion
end

o = TestVersion.new

puts o.getVersion

puts o.current?

puts o.diffirence