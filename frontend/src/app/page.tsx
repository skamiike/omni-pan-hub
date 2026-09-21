import Link from 'next/link';

export default function Home() {
  return (
    <main className="min-h-screen bg-black text-white flex flex-col items-center justify-center p-24">
      <h1 className="text-6xl font-bold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-purple-600">
        Omni-Pan Hub
      </h1>
      <p className="text-xl mb-8 text-gray-400">Web3 All-Genre Creator Matching Platform</p>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 w-full max-w-4xl">
        <div className="p-6 border border-gray-800 rounded-xl bg-gray-900/50 backdrop-blur-sm hover:border-blue-500 transition-colors">
          <h2 className="text-2xl font-bold mb-2">For Creators</h2>
          <p className="text-gray-400 mb-4">Set up your custom profile and start taking Web3 commissions with only 5% fee.</p>
          <Link href="/creator-setup" className="inline-block px-6 py-2 bg-blue-600 hover:bg-blue-700 rounded-full font-medium">
            Setup Profile
          </Link>
        </div>
        
        <div className="p-6 border border-gray-800 rounded-xl bg-gray-900/50 backdrop-blur-sm hover:border-purple-500 transition-colors">
          <h2 className="text-2xl font-bold mb-2">For Clients</h2>
          <p className="text-gray-400 mb-4">Browse creators, pay with crypto, and get your commissions automatically minted as NFTs.</p>
          <Link href="/explore" className="inline-block px-6 py-2 bg-purple-600 hover:bg-purple-700 rounded-full font-medium">
            Explore Creators
          </Link>
        </div>
      </div>
      
      <div className="mt-12 text-gray-500">
        <p>Demo: Check out a sample creator profile at <Link href="/artist123" className="text-blue-400 hover:underline">/artist123</Link></p>
      </div>
    </main>
  );
}
