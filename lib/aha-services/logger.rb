require 'logger'

class AhaLogger < Logger
  def info(progname = nil, &block)
    super(progname, &block) unless $TEST_ENV
  end

  def debug(progname = nil, &block)
    super(progname, &block) unless $TEST_ENV
  end

  def warn(progname = nil, &block)
    super(progname, &block) unless $TEST_ENV
  end

  def error(progname = nil, &block)
    super(progname, &block) unless $TEST_ENV
  end
end