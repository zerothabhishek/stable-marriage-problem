
Prefs_m = {
  'abe' => %W(abi eve cath ivy jan dee fay bea hope gay),
  'bob' => %W(cath hope abi dee eve fay bea jan ivy gay),
  'col' => %W(hope eve abi dee bea fay ivy gay cath jan),
  'dan' => %W(ivy fay dee gay hope eve jan bea cath abi),
   'ed' => %W(jan dee bea cath fay eve abi ivy hope gay),
 'fred' => %W(bea abi dee gay eve ivy cath jan hope fay),
  'gav' => %W(gay eve ivy bea cath abi dee hope jan fay),
  'hal' => %W(abi eve hope fay ivy cath jan bea gay dee),
  'ian' => %W(hope cath dee gay bea abi fay ivy jan eve),
  'jon' => %W(abi fay jan gay eve bea dee cath ivy hope),
}


Prefs_f = {
  'abi' => %W(bob fred jon gav ian abe dan ed col hal),
  'bea' => %W(bob abe col fred gav dan ian ed jon hal),
 'cath' => %W(fred bob ed gav hal col ian abe dan jon),
  'dee' => %W(fred jon col abe ian hal gav dan bob ed),
  'eve' => %W(jon hal fred dan abe gav col ed ian bob),
  'fay' => %W(bob abe ed ian jon dan fred gav col hal),
  'gay' => %W(jon gav hal fred bob abe col ed dan ian),
 'hope' => %W(gav jon bob abe ian dan hal ed col fred),
  'ivy' => %W(ian col hal gav fred bob abe ed jon dan),
  'jan' => %W(ed hal gav abe bob jon col ian fred dan),
}

Males = Prefs_m.keys
Females = Prefs_f.keys

class Pair
	attr_accessor :m, :f

	def initialize(m,f)
		@m, @f = m, f
	end

	def prefs_for_f
		@prefs_for_f ||= Prefs_m[@m]
	end

	def prefs_for_m
		@prefs_for_m ||= Prefs_f[@f]
	end

	def can_coexist?(males, females)
		f_can_coexists?(males) &&
		m_can_coexist?(females)
	end

	def f_can_coexists?(males)
		_can_coexists?(spouse: @m, group: males, prefs: prefs_for_f)
	end

	def m_can_coexist?(females)
		_can_coexists?(spouse: @f, group: females, prefs: prefs_for_m)
	end

	def _can_coexists?(spouse:, group:, prefs:)
		others = group - [spouse]
		spouse_rank = ranks[spouse]
		others_ranks = others.map{|x| prefs.index(x)}.compact + [0]
		spouse_rank > others_ranks.max
	end

	def ranks
		@ranks ||= begin
			ranks = {}
			ranks[@m] = prefs_for_m.index(@m)
			ranks[@f] = prefs_for_f.index(@f)
			ranks
		end
	end

	def inspect
		"#<#{@m}, #{@f}>"
	end

	def self.random
		Pair.new(Males.sample, Females.sample)
	end
end

StableMemory = {}

class MSet
	attr_accessor :pairs

	def initialize(pairs)
		@pairs = pairs
		@stable_memory = {}
	end

	def size
		@pairs.size
	end

	def add!(pair)
		add(pairs) or raise 'Invalid addition'
	end

	def add(pair)
		new_set = MSet.new(@pairs + [pair])
		new_set.valid? ? new_set : nil
	end

	def males
		@pairs.map &:m
	end

	def females
		@pairs.map &:f
	end

	def valid?
		males.uniq.count == males.count &&
		females.uniq.count == females.count
	end

	def stable?
		val = @pairs.all? do |pair|
			pair.can_coexist?(males, females)
		end
	end

	def hash2
		inspect
	end

	def inspect
		"#<MSet: " + @pairs.map(&:inspect).join(" ") + ">"
	end

end



def expand_m(set)
	result_sets = []
	m = set.males.last

	last = set.size
	possible_ms = Males[(Males.index(m)+1)..(-last)]
	possible_ms.each do |possible_m|
		possible_fs = Prefs_m[possible_m]
		possible_pairs = [possible_m].product(possible_fs).map{|(m,f)| Pair.new(m,f)}
		possible_sets = possible_pairs.map{|pair| set.add(pair)}.compact
		possible_stable_sets = possible_sets.select{|set| set.stable? }
		result_sets += possible_stable_sets
	end
	result_sets
end

def expand_f(set)
	result_sets = []
	f = set.females.last

	last = set.size
	possible_fs = Females[(Females.index(f)+1)..(-last)]
	possible_fs.map do |possible_f|
		possible_ms = Prefs_f[possible_f]
		possible_pairs = possible_ms.product([possible_f]).map{|(m,f)| Pair.new(m,f)}
		possible_sets = possible_pairs.map{|pair| set.add(pair) }.compact
		possible_stable_sets = possible_sets.select{|set| set.stable? }
		result_sets += possible_stable_sets
	end
	result_sets
end

def expand(set)
	(expand_m(set) + expand_f(set)).uniq
end

def build_set_list
	pairs = Males.product(Females).map{|(m,f)| Pair.new(m,f)}
	sets = pairs.map{|pair| MSet.new([pair]) }
end


def run
	i = 0
	set_list = build_set_list
	expanded_sets_uniq = []
	common = []
	loop do

		set = set_list[i]		
		expanded_sets = expand(set)
		expanded_sets_uniq = expanded_sets

		unless expanded_sets_uniq.empty?
			set_list += expanded_sets_uniq
		end

		if set==set_list.last
			break
		end
		i += 1
	end
	final_result = set_list.last
end

p run() if __FILE__==$0